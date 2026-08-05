from app.database.models.taluka import Taluka
from app.repositories.cache.base_cache_repository import BaseCacheRepository


class TalukaCacheRepository(BaseCacheRepository[Taluka]):

    def __init__(self):
        super().__init__(Taluka)

    def get_by_district(self, district_code: str):
        return (
            self.db.query(Taluka)
            .filter(Taluka.district_code == district_code)
            .order_by(Taluka.taluka_name)
            .all()
        )