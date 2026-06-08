import io
import time
import logging
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
import torch
from PIL import Image, ImageOps, ImageFilter
from scipy import ndimage

logger = logging.getLogger(__name__)

IMG_SIZE = 64
PRE_RESIZE = 512
MARGIN = 8
EXTRA_PADDING_RATIO = 0.12
TTA_ROTATIONS = [0]


def _save_step(images_test_dir: Path, tag: str, step_name: str, arr: np.ndarray) -> None:
    """Save a processing step as grayscale PNG for debug visualization."""
    try:
        images_test_dir.mkdir(exist_ok=True)
        Image.fromarray(arr.astype(np.uint8), mode="L").save(
            str(images_test_dir / f"{tag}_{step_name}.png")
        )
    except Exception as exc:
        logger.warning("Could not save debug step '%s': %s", step_name, exc)



@dataclass
class ProcessingResult:
    tensor: torch.Tensor  # float32, shape [1, 1, IMG_SIZE, IMG_SIZE]
    debug_png: bytes


def preprocess_image(image_buffer: bytes, images_test_dir: Path, rotation: int = 0) -> ProcessingResult:
    tag = str(int(time.time() * 1000))

    # --- Step 1: Load, EXIF auto-orient, TTA rotation, grayscale, pre-resize ---
    img = Image.open(io.BytesIO(image_buffer))
    img = ImageOps.exif_transpose(img)

    if rotation != 0:
        img = img.rotate(-rotation, expand=True)

    img = img.convert("L")
    img.thumbnail((PRE_RESIZE, PRE_RESIZE), Image.LANCZOS)

    # --- Step 2: Gaussian blur (PIL radius=0.7) ---
    img = img.filter(ImageFilter.GaussianBlur(radius=0.7))
    arr = np.array(img).astype(np.uint8)

    _save_step(images_test_dir, tag, "1_grayscale", arr)

    # --- Step 3: CLAHE — equalização local de histograma, neutraliza sombras e iluminação não-uniforme ---
    # tileGridSize divide a imagem em tiles; cada tile é equalizado independentemente
    # clipLimit limita o ganho máximo para não amplificar ruído
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    arr_eq = clahe.apply(arr)
    _save_step(images_test_dir, tag, "1b_clahe", arr_eq)

    # --- Step 4: Adaptive threshold — threshold local por vizinhança (substitui Otsu global) ---
    # ADAPTIVE_THRESH_GAUSSIAN_C: pondera pixels vizinhos por gaussiana (mais suave que MEAN_C)
    # THRESH_BINARY_INV: traços escuros → 255 (branco), papel claro → 0 (preto)
    # blockSize: tamanho da vizinhança em px (deve ser ímpar). ~10% do PRE_RESIZE é ponto de partida.
    # C: constante subtraída da média ponderada. Aumentar → menos ruído. Diminuir → captura traços finos.
    mask_uint8 = cv2.adaptiveThreshold(
        arr_eq,
        maxValue=255,
        adaptiveMethod=cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        thresholdType=cv2.THRESH_BINARY_INV,
        blockSize=51,
        C=10,
    )
    mask = mask_uint8 > 0
    _save_step(images_test_dir, tag, "2_rawMask", mask_uint8)

    # --- Step 4: Morphological closing (2×2 kernel, joins nearby stroke fragments) ---
    mask = ndimage.binary_closing(mask, structure=np.ones((2, 2)))

    _save_step(images_test_dir, tag, "3_closedMask", (mask * 255).astype(np.uint8))

    # --- Step 5: Connected components — filter out small noise ---
    labeled, num_features = ndimage.label(mask)

    if num_features == 0:
        raise ValueError("No strokes detected in image.")

    objects = ndimage.find_objects(labeled)
    areas = []
    for i, obj in enumerate(objects, start=1):
        if obj is None:
            areas.append(0)
            continue
        areas.append(int((labeled[obj] == i).sum()))

    area_threshold = max(20, max(areas) * 0.08)
    logger.info("Components: %d  max_area: %d  threshold: %.1f", num_features, max(areas), area_threshold)

    clean_mask = np.zeros_like(mask, dtype=bool)
    for i, area in enumerate(areas, start=1):
        if area >= area_threshold:
            clean_mask[labeled == i] = True

    _save_step(images_test_dir, tag, "4_cleanMask", (clean_mask * 255).astype(np.uint8))

    # --- Step 6: Bounding box of all kept stroke pixels ---
    coords = np.argwhere(clean_mask)
    if coords.size == 0:
        raise ValueError("No character detected after cleanup.")

    y0, x0 = coords.min(axis=0)
    y1, x1 = coords.max(axis=0)

    # --- Step 7: Crop with margin, clamped to image bounds ---
    h, w = clean_mask.shape
    x0 = max(x0 - MARGIN, 0)
    y0 = max(y0 - MARGIN, 0)
    x1 = min(x1 + MARGIN, w - 1)
    y1 = min(y1 + MARGIN, h - 1)

    cropped_mask = clean_mask[y0 : y1 + 1, x0 : x1 + 1]

    _save_step(images_test_dir, tag, "5_crop", (cropped_mask * 255).astype(np.uint8))

    # --- Step 8: White strokes on black square canvas ---
    binary_img = Image.fromarray((cropped_mask * 255).astype(np.uint8), mode="L")

    bw, bh = binary_img.size
    max_side = max(bw, bh)
    square = Image.new("L", (max_side, max_side), color=0)
    square.paste(binary_img, ((max_side - bw) // 2, (max_side - bh) // 2))

    # --- Step 9: Extra padding around square (12% of side) ---
    extra_padding = int(max_side * EXTRA_PADDING_RATIO)
    square = ImageOps.expand(square, border=extra_padding, fill=0)

    _save_step(images_test_dir, tag, "6_square", np.array(square))

    # --- Step 10: Thumbnail fit + center on final IMG_SIZE×IMG_SIZE canvas ---
    square.thumbnail((IMG_SIZE, IMG_SIZE), Image.LANCZOS)

    final_canvas = Image.new("L", (IMG_SIZE, IMG_SIZE), color=0)
    final_canvas.paste(square, ((IMG_SIZE - square.size[0]) // 2, (IMG_SIZE - square.size[1]) // 2))

    final_arr = np.array(final_canvas).astype(np.float32) / 255.0

    _save_step(images_test_dir, tag, "7_final64x64", (final_arr * 255).astype(np.uint8))

    # --- Step 11: Torch tensor [1, 1, IMG_SIZE, IMG_SIZE] ---
    tensor = torch.tensor(final_arr).unsqueeze(0).unsqueeze(0)

    debug_buf = io.BytesIO()
    final_canvas.save(debug_buf, format="PNG")

    return ProcessingResult(tensor=tensor, debug_png=debug_buf.getvalue())
