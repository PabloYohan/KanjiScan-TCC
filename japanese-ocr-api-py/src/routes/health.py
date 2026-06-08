import time
from datetime import datetime, timezone

from fastapi import APIRouter

from src.utils.response import success_response

router = APIRouter()
_START_TIME = time.monotonic()


@router.get("/health")
async def health_check():
    return success_response(
        {
            "status": "ok",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "uptime": round(time.monotonic() - _START_TIME, 3),
        }
    )
