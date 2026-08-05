from typing import List
from app.repositories.remote.village_repository import VillageRepository
from app.schemas.village import (
    DistrictSchema,
    TalukaSchema,
    VillageSchema,
    GISCodeResponse,
)


class VillageService:
    def __init__(self, repository: VillageRepository):
        self.repository = repository

    async def get_districts(self) -> List[DistrictSchema]:
        districts = await self.repository.fetch_districts()
        return [
            DistrictSchema(
                district_code=d.district_code,
                district_name=d.district_name,
                state_code=d.state_code,
            )
            for d in districts
        ]

    async def get_talukas(self, district_code: str) -> List[TalukaSchema]:
        talukas = await self.repository.fetch_talukas(district_code)
        return [
            TalukaSchema(
                taluka_code=t.taluka_code,
                taluka_name=t.taluka_name,
                district_code=t.district_code,
            )
            for t in talukas
        ]

    async def get_villages(
        self, district_code: str, taluka_code: str
    ) -> List[VillageSchema]:
        villages = await self.repository.fetch_villages(district_code, taluka_code)
        return [
            VillageSchema(
                village_code=v.village_code,
                village_name=v.village_name,
                taluka_code=v.taluka_code,
                gis_code=v.gis_code,
            )
            for v in villages
        ]

    async def resolve_village_gis_code(
        self, district_code: str, taluka_code: str, village_code: str
    ) -> GISCodeResponse:
        gis_code = await self.repository.resolve_gis_code(
            district_code, taluka_code, village_code
        )
        return GISCodeResponse(
            village_code=village_code,
            gis_code=gis_code,
            state="Maharashtra",
            is_valid=True,
        )
