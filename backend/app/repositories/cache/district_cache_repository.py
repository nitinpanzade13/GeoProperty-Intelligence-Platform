from typing import List

from app.database.models.district import District
from app.repositories.cache.base_cache_repository import BaseCacheRepository


class DistrictCacheRepository(BaseCacheRepository[District]):

    def __init__(self):
        super().__init__(District)

    def save_all(self, data: List[District]) -> None:
        """
        Add/update districts without deleting existing districts.
        """
        for district in data:
            self.db.merge(district)

        self.db.commit()