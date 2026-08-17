from app.repositories.admin_dashboard_repository import (
    AdminDashboardRepository,
)


class AdminDashboardService:
    """
    Business service for admin dashboard operations.
    """

    def __init__(
        self,
        repository: AdminDashboardRepository,
    ):
        self.repository = repository

    async def get_summary(self) -> dict:
        try:
            return self.repository.get_summary()
        finally:
            self.repository.close()

    async def get_district_overview(self) -> list[dict]:
        try:
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