from typing import List
from app.repositories.remote.village_repository import VillageRepository

from app.schemas.village import (
    DistrictSchema,
    TalukaSchema,
    VillageSchema,
    GISCodeResponse,
)
from app.repositories.cache.district_cache_repository import (
    DistrictCacheRepository,
)
from app.repositories.cache.taluka_cache_repository import TalukaCacheRepository
from app.repositories.cache.village_cache_repository import VillageCacheRepository


class VillageService:
    def __init__(self, repository: VillageRepository, 
                 district_cache_repository: DistrictCacheRepository,
                 taluka_cache_repository: TalukaCacheRepository,
                 village_cache_repository: VillageCacheRepository):
        self.repository = repository
        self.district_cache_repository = district_cache_repository
        self.taluka_cache_repository = taluka_cache_repository
        self.village_cache_repository = village_cache_repository

    async def get_districts(self) -> List[DistrictSchema]:

        # -----------------------------
        # 1. Try PostgreSQL cache
        # -----------------------------
        cached_districts = self.district_cache_repository.get_all()

        if cached_districts:

            print("✅ Districts loaded from PostgreSQL cache")

            return [
                DistrictSchema(
                    district_code=d.district_code,
                    district_name=d.district_name,
                    state_code=d.state_code,
                )
                for d in cached_districts
            ]

        # -----------------------------
        # 2. Cache miss -> Fetch remotely
        # -----------------------------
        print("🌐 Districts loaded from Maharashtra BhuNaksha")

        districts = await self.repository.fetch_districts()

        # -----------------------------
        # 3. Save into PostgreSQL
        # -----------------------------
        from app.database.models.district import District

        self.district_cache_repository.save_all(
            [
                District(
                    district_code=d.district_code,
                    district_name=d.district_name,
                    state_code=d.state_code,
                )
                for d in districts
            ]
        )

        # -----------------------------
        # 4. Return response
        # -----------------------------
        return [
            DistrictSchema(
                district_code=d.district_code,
                district_name=d.district_name,
                state_code=d.state_code,
            )
            for d in districts
        ]

    async def get_talukas(
        self,
        district_code: str,
    ) -> List[TalukaSchema]:

        # -----------------------------
        # 1. Try PostgreSQL cache
        # -----------------------------
        cached_talukas = self.taluka_cache_repository.get_by_district(
            district_code
        )

        if cached_talukas:

            print("✅ Talukas loaded from PostgreSQL cache")

            return [
                TalukaSchema(
                    taluka_code=t.taluka_code,
                    taluka_name=t.taluka_name,
                    district_code=t.district_code,
                )
                for t in cached_talukas
            ]

        # -----------------------------
        # 2. Cache miss
        # -----------------------------
        print("🌐 Talukas loaded from Maharashtra BhuNaksha")

        talukas = await self.repository.fetch_talukas(district_code)

        # -----------------------------
        # 3. Save into PostgreSQL
        # -----------------------------
        from app.database.models.taluka import Taluka

        self.taluka_cache_repository.save_all(
            [
                Taluka(
                    taluka_code=t.taluka_code,
                    taluka_name=t.taluka_name,
                    district_code=t.district_code,
                )
                for t in talukas
            ]
        )

        # -----------------------------
        # 4. Return response
        # -----------------------------
        return [
            TalukaSchema(
                taluka_code=t.taluka_code,
                taluka_name=t.taluka_name,
                district_code=t.district_code,
            )
            for t in talukas
        ]

    async def get_villages(
        self,
        district_code: str,
        taluka_code: str,
    ) -> List[VillageSchema]:

        # ----------------------------------
        # 1. Try PostgreSQL cache
        # ----------------------------------
        cached_villages = self.village_cache_repository.get_by_taluka(
            district_code = district_code,
            taluka_code = taluka_code
        )

        if cached_villages:

            print("✅ Villages loaded from PostgreSQL cache")

            return [
                VillageSchema(
                    village_code=v.village_code,
                    village_name=v.village_name,
                    taluka_code=v.taluka_code,
                    gis_code=v.gis_code,
                )
                for v in cached_villages
            ]

        # ----------------------------------
        # 2. Cache miss -> Fetch from BhuNaksha
        # ----------------------------------
        print("🌐 Villages loaded from Maharashtra BhuNaksha")

        villages = await self.repository.fetch_villages(
            district_code,
            taluka_code,
        )

        # ----------------------------------
        # 3. Save to PostgreSQL
        # ----------------------------------
        from app.database.models.village import Village

        self.village_cache_repository.save_all(
            [
                Village(
                    gis_code=v.gis_code,
                    village_code=v.village_code,
                    village_name=v.village_name,
                    district_code=district_code,
                    taluka_code=v.taluka_code,
                )
                for v in villages
            ]
        )

        # ----------------------------------
        # 4. Return response
        # ----------------------------------
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
