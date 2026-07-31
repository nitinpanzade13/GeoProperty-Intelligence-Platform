import time
from typing import Dict, Any, Optional
from app.core.config import settings
from app.core.logging import logger


class CacheItem:
    def __init__(self, value: Any, ttl_seconds: int):
        self.value = value
        self.expires_at = time.time() + ttl_seconds

    def is_expired(self) -> bool:
        return time.time() > self.expires_at


class MemoryCache:
    def __init__(self):
        self._cache: Dict[str, CacheItem] = {}

    def get(self, key: str) -> Optional[Any]:
        item = self._cache.get(key)
        if item is None:
            return None
        if item.is_expired():
            logger.info(f"Cache expired for key: {key}")
            del self._cache[key]
            return None
        logger.info(f"Cache hit for key: {key}")
        return item.value

    def set(self, key: str, value: Any, ttl_seconds: Optional[int] = None) -> None:
        ttl = ttl_seconds if ttl_seconds is not None else settings.CACHE_DEFAULT_TTL_SECONDS
        self._cache[key] = CacheItem(value=value, ttl_seconds=ttl)
        logger.info(f"Cache set for key: {key} (TTL: {ttl}s)")

    def clear(self) -> None:
        self._cache.clear()


memory_cache = MemoryCache()
