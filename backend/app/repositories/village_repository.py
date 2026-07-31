from typing import List
from app.providers.base_provider import LandRecordsProvider
from app.models.domain_models import District, Taluka, Village


class VillageRepository:
    def __init__(self, provider: LandRecordsProvider):
        self.provider = provider

    async def fetch_districts(self) -> List[District]:
        return await self.provider.get_districts()

    async def fetch_talukas(self, district_code: str) -> List[Taluka]:
        return await self.provider.get_talukas(district_code)

    async def fetch_villages(self, district_code: str, taluka_code: str) -> List[Village]:
        return await self.provider.get_villages(district_code, taluka_code)

    async def resolve_gis_code(
        self, district_code: str, taluka_code: str, village_code: str
    ) -> str:
        return await self.provider.get_village_gis_code(
            district_code, taluka_code, village_code
        )
