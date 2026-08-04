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

    # CORS Configuration
    # Explicit origins for fixed ports, regex pattern for dynamic Flutter Web ports on localhost / 127.0.0.1
    CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:8000",
        "http://localhost:3000",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
    ]
    CORS_ORIGIN_REGEX: str = r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"

    # HTTPX Client Configuration
    HTTP_TIMEOUT_SECONDS: float = 30.0
    HTTP_MAX_RETRIES: int = 3
    HTTP_POOL_LIMITS_MAX_KEEPALIVE: int = 10
    HTTP_POOL_LIMITS_MAX_CONNECTIONS: int = 100

    # Cache Configuration
    CACHE_DEFAULT_TTL_SECONDS: int = 3600  # 1 Hour
    CACHE_VILLAGE_TTL_SECONDS: int = 86400  # 24 Hours
    CACHE_SURVEY_TTL_SECONDS: int = 1800   # 30 Mins

    # External Provider Configuration
    DEFAULT_STATE_PROVIDER: str = "MH"
    MH_BHUNAKSHA_BASE_URL: str = "https://mahabhunakasha.mahabhumi.gov.in/bhunaksha/services"

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings()
