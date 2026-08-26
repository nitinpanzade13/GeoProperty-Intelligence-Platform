from app.repositories.admin_dashboard_repository import (
    AdminDashboardRepository,
)
from app.repositories.cache.district_cache_repository import DistrictCacheRepository
from app.repositories.remote.village_repository import VillageRepository


class AdminDashboardService:
    """
    Business service for admin dashboard operations.
    """

    def __init__(
        self,
        repository: AdminDashboardRepository,
        district_cache_repository: DistrictCacheRepository,
        village_repository: VillageRepository,
    ):
        self.repository = repository
        self.district_cache_repository = district_cache_repository
        self.village_repository = village_repository

    async def get_summary(self) -> dict:
        try:
            return self.repository.get_summary()
        finally:
            self.repository.close()

    async def get_district_overview(self) -> list[dict]:
        try:
            districts = self.repository.get_district_overview()

            if districts:
                return districts

            remote_districts = await self.village_repository.fetch_districts()

            if not remote_districts:
                return []

            self.district_cache_repository.save_all(remote_districts)

            return self.repository.get_district_overview()
        finally:
            self.repository.close()

    async def get_taluka_overview(
        self,
        district_code: str,
    ) -> list[dict]:
        try:
            return self.repository.get_taluka_overview(
                district_code
            )
        finally:
            self.repository.close()

    async def get_village_overview(
        self,
        district_code: str,
        taluka_code: str,
    ) -> list[dict]:
        try:
            return self.repository.get_village_overview(
                district_code,
                taluka_code,
            )
        finally:
            self.repository.close()