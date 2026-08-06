try:
    from pydantic_settings import BaseSettings
except ImportError:
    try:
        from pydantic.v1 import BaseSettings  # type: ignore
    except ImportError:
        from pydantic import BaseSettings  # type: ignore

from typing import List, Literal


class Settings(BaseSettings):
    # ============================================================
    # Application
    # ============================================================

    PROJECT_NAME: str = "GeoProperty Intelligence Platform - Property Radar"
    VERSION: str = "2.0.0"

    API_V1_STR: str = "/api/v1"
    API_V2_STR: str = "/api"

    ENVIRONMENT: Literal[
        "development",
        "staging",
        "production",
    ]

    DEBUG: bool

    # ============================================================
    # Database
    # ============================================================

    DATABASE_URL: str

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
    HTTP_RETRY_DELAY_SECONDS: float = 1.0

    HTTP_POOL_LIMITS_MAX_KEEPALIVE: int = 10
    HTTP_POOL_LIMITS_MAX_CONNECTIONS: int = 100

    HTTP_USER_AGENT: str = (
        "GeoProperty-Intelligence-Platform/2.0"
    )

    REQUEST_DELAY_MS: int = 0

    # ============================================================
    # In-Memory Cache Configuration
    # ============================================================

    CACHE_DEFAULT_TTL_SECONDS: int = 3600
    CACHE_VILLAGE_TTL_SECONDS: int = 86400
    CACHE_SURVEY_TTL_SECONDS: int = 1800

    # ============================================================
    # PostgreSQL Cache Configuration
    # ============================================================

    CACHE_REFRESH_DAYS: int = 30

    ENABLE_BACKGROUND_REFRESH: bool = True
    MAX_BACKGROUND_REFRESHES: int = 5
    CACHE_CLEANUP_INTERVAL_HOURS: int = 24

    # ============================================================
    # GeoJSON Configuration
    # ============================================================

    MAX_PARALLEL_SURVEY_REQUESTS: int = 20
    MAX_SURVEYS_PER_VILLAGE: int = 5000

    # ============================================================
    # Compression
    # ============================================================

    ENABLE_GZIP: bool = True
    GZIP_MINIMUM_SIZE: int = 1000

    # ============================================================
    # Logging
    # ============================================================

    ENABLE_PERFORMANCE_LOGGING: bool = True
    LOG_SLOW_REQUEST_THRESHOLD_MS: int = 1000

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