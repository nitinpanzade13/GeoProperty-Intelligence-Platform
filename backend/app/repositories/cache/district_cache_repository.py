from typing import List

from app.database.models.district import District as DistrictModel
from app.repositories.cache.base_cache_repository import BaseCacheRepository
from app.models.domain_models import District as DomainDistrict

class DistrictCacheRepository(BaseCacheRepository[DistrictModel]):

    def __init__(self):
        super().__init__(DistrictModel)

    def save_all(self, data: List[DomainDistrict]) -> None:
        """
        Add/update districts without deleting existing districts.
        Converts domain District objects into SQLAlchemy District models.
        """

        for district in data:
            district_model = DistrictModel(
                district_code=district.district_code,
                district_name=district.district_name,
                state_code=district.state_code,
            )

            self.db.merge(district_model)  # Use merge to add or update the district

        self.db.commit()