from functools import lru_cache
from pathlib import Path
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    port: int = 3000
    host: str = "0.0.0.0"
    environment: str = "development"
    max_file_size: int = 5 * 1024 * 1024  # 5MB

    model_config = {"env_file": ".env", "extra": "ignore"}

    @property
    def ai_model_dir(self) -> Path:
        return Path(__file__).parent.parent / "ai_model"

    @property
    def images_test_dir(self) -> Path:
        return Path(__file__).parent.parent.parent / "images_test"


@lru_cache
def get_settings() -> Settings:
    return Settings()
