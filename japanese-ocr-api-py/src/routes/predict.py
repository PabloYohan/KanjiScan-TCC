import logging

from fastapi import APIRouter, UploadFile, File

from src.config.settings import get_settings
from src.services.inference import InferenceService
from src.utils.response import error_response, success_response

logger = logging.getLogger(__name__)
router = APIRouter()

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp", "image/bmp"}


@router.post("/predict")
async def predict(image: UploadFile = File(...)):
    if not image.content_type or image.content_type not in ALLOWED_MIME_TYPES:
        return error_response(
            "INVALID_FILE_TYPE",
            f"Unsupported file type '{image.content_type}'. Use JPEG, PNG, WebP, or BMP.",
            415,
        )

    content = await image.read()

    settings = get_settings()
    if len(content) > settings.max_file_size:
        return error_response(
            "FILE_TOO_LARGE",
            f"File exceeds the {settings.max_file_size // (1024 * 1024)} MB limit.",
            413,
        )

    try:
        result = await InferenceService().predict(content)
        return success_response(
            {
                "label": result.label,
                "confidence": result.confidence,
                "meaning": result.meaning,
            }
        )
    except FileNotFoundError as exc:
        logger.error("Model file not found: %s", exc)
        return error_response("MODEL_NOT_FOUND", "AI model files are missing. Check src/ai_model/.", 500)
    except Exception as exc:
        logger.exception("Prediction failed")
        return error_response("INTERNAL_ERROR", str(exc), 500)
