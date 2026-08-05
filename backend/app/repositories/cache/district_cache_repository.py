from app.database.models.district import District
from app.repositories.cache.base_cache_repository import BaseCacheRepository


class DistrictCacheRepository(BaseCacheRepository[District]):

    def __init__(self):
        super().__init__(District)