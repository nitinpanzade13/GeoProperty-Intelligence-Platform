from app.database.models.village import Village
from app.repositories.cache.base_cache_repository import BaseCacheRepository


class VillageCacheRepository(BaseCacheRepository[Village]):

    def __init__(self):
        super().__init__(Village)

    def get_by_taluka(self, taluka_code: str):
        return (
            self.db.query(Village)
            .filter(Village.taluka_code == taluka_code)
            .order_by(Village.village_name)
            .all()
        )