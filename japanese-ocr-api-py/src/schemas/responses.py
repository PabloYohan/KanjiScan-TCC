from typing import Any, Optional
from pydantic import BaseModel


class ErrorDetail(BaseModel):
    code: str
    message: str


class ApiResponse(BaseModel):
    success: bool
    data: Optional[Any] = None
    error: Optional[ErrorDetail] = None


class HealthData(BaseModel):
    status: str
    timestamp: str
    uptime: float


class PredictionData(BaseModel):
    label: str
    confidence: float
    meaning: str
