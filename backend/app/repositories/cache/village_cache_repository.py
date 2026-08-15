from typing import List

from app.database.models.village import Village
from app.repositories.cache.base_cache_repository import BaseCacheRepository


class VillageCacheRepository(BaseCacheRepository[Village]):

    def __init__(self):
        super().__init__(Village)

    def get_by_taluka(
        self,
        district_code: str,
        taluka_code: str,
    ):
        return (
            self.db.query(Village)
            .filter(
                Village.district_code == district_code,
                Village.taluka_code == taluka_code,
            )
            .order_by(Village.village_name)
            .all()
        )

    def save_all(self, data: List[Village]) -> None:
        """
        Add/update villages without deleting existing villages.
        GIS code is the primary key, so merge() safely handles
        already-existing villages.
        """
        for village in data:
            self.db.merge(village)

        self.db.commit()