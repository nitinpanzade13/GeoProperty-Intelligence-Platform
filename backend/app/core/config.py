try:
    from pydantic_settings import BaseSettings
except ImportError:
    try:
        from pydantic.v1 import BaseSettings  # type: ignore
    except ImportError:
        from pydantic import BaseSettings  # type: ignore

from typing import List


class Settings(BaseSettings):
    PROJECT_NAME: str = "GeoProperty Intelligence Platform - Property Radar"
    VERSION: str = "2.0.0"

    API_V1_STR: str = "/api/v1"
    API_V2_STR: str = "/api"

    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # ============================================================
    # CORS Configuration
    # ============================================================

    CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:8000",
        "http://localhost:3000",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
    ]

    CORS_ORIGIN_REGEX: str = (
        r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"
    )

    # ============================================================
    # HTTP Client Configuration
    # ============================================================

    HTTP_TIMEOUT_SECONDS: float = 30.0
    HTTP_MAX_RETRIES: int = 3

    HTTP_POOL_LIMITS_MAX_KEEPALIVE: int = 10
    HTTP_POOL_LIMITS_MAX_CONNECTIONS: int = 100

    # ============================================================
    # In-Memory Cache Configuration
    # ============================================================

    CACHE_DEFAULT_TTL_SECONDS: int = 3600
    CACHE_VILLAGE_TTL_SECONDS: int = 86400
    CACHE_SURVEY_TTL_SECONDS: int = 1800

    # ============================================================
    # PostgreSQL Cache Configuration
    # ============================================================

    CACHE_REFRESH_DAYS: int = 0

    # Automatically refresh stale cache
    ENABLE_BACKGROUND_REFRESH: bool = True

    # ============================================================
    # GeoJSON Configuration
    # ============================================================

    MAX_PARALLEL_SURVEY_REQUESTS: int = 20

    ENABLE_GZIP: bool = True

    # ============================================================
    # Logging
    # ============================================================

    ENABLE_PERFORMANCE_LOGGING: bool = True

    # ============================================================
    # External Provider
    # ============================================================

    DEFAULT_STATE_PROVIDER: str = "MH"

    MH_BHUNAKSHA_BASE_URL: str = (
        "https://mahabhunakasha.mahabhumi.gov.in/bhunaksha/services"
    )

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings()