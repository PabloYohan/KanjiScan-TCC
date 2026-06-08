import asyncio
import json
import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import numpy as np
import torch
import torch.nn.functional as F
import onnxruntime as ort

from src.services.image_processing import preprocess_image, TTA_ROTATIONS
from src.config.settings import get_settings

logger = logging.getLogger(__name__)


@dataclass
class InferenceResult:
    label: str
    confidence: float
    meaning: str


class InferenceService:
    """Lazy-loaded singleton ONNX inference session with TTA support."""

    _session: Optional[ort.InferenceSession] = None
    _classes: Optional[list] = None
    _meanings: Optional[dict] = None

    @classmethod
    def _get_session(cls) -> ort.InferenceSession:
        if cls._session is None:
            model_path = get_settings().ai_model_dir / "best_cnn_model.onnx"
            cls._session = ort.InferenceSession(str(model_path))
            logger.info("ONNX inference session loaded from %s", model_path)
        return cls._session

    @classmethod
    def _get_classes(cls) -> list:
        if cls._classes is None:
            path = get_settings().ai_model_dir / "classes.json"
            with open(path, encoding="utf-8") as f:
                cls._classes = json.load(f)
        return cls._classes

    @classmethod
    def _get_meanings(cls) -> dict:
        if cls._meanings is None:
            path = get_settings().ai_model_dir / "meaning.json"
            with open(path, encoding="utf-8") as f:
                cls._meanings = json.load(f)
        return cls._meanings

    async def predict(self, image_buffer: bytes) -> InferenceResult:
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, self._predict_sync, image_buffer)

    def _predict_sync(self, image_buffer: bytes) -> InferenceResult:
        session = self._get_session()
        classes = self._get_classes()
        meanings = self._get_meanings()
        images_test_dir = get_settings().images_test_dir

        best_result: Optional[InferenceResult] = None
        best_confidence = -1.0

        for rotation in TTA_ROTATIONS:
            try:
                proc = preprocess_image(image_buffer, images_test_dir, rotation)

                # tensor already has shape [1, 1, 64, 64] — convert to numpy for ONNX
                input_data = proc.tensor.numpy()
                input_name = session.get_inputs()[0].name
                raw_output = session.run(None, {input_name: input_data})
                logits = raw_output[0].flatten()

                # Use torch for numerically stable softmax + argmax
                probs = F.softmax(torch.from_numpy(logits.copy()), dim=0)
                confidence_val, pred_idx = probs.max(dim=0)

                confidence = float(confidence_val)
                label = classes[int(pred_idx)]
                meaning = meanings.get(label, "")

                logger.info("Rotation %d°: %s  (%.2f%%)", rotation, label, confidence * 100)

                if confidence > best_confidence:
                    best_confidence = confidence
                    best_result = InferenceResult(
                        label=label,
                        confidence=round(confidence, 4),
                        meaning=meaning,
                    )

            except Exception as exc:
                logger.warning("TTA rotation %d° failed: %s", rotation, exc)

        if best_result is None:
            raise RuntimeError("All TTA rotations failed during inference")

        return best_result
