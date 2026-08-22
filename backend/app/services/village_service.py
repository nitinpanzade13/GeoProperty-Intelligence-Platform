from typing import List

from app.schemas.village import (
    DistrictSchema,
    TalukaSchema,
    VillageSchema,
    GISCodeResponse,
)

from app.repositories.cache.district_cache_repository import (
    DistrictCacheRepository,
)
from app.repositories.cache.taluka_cache_repository import (
    TalukaCacheRepository,
)
from app.repositories.cache.village_cache_repository import (
    VillageCacheRepository,
)


class VillageService:
    """
    Service for reading administrative location data.

    IMPORTANT:
    Normal application requests are PostgreSQL-only.

    This service NEVER calls BhuNaksha directly.

    BhuNaksha synchronization is handled explicitly by
    AdminSyncService.
    """

    def __init__(
        self,
        district_cache_repository: DistrictCacheRepository,
        taluka_cache_repository: TalukaCacheRepository,
        village_cache_repository: VillageCacheRepository,
    ):
        self.district_cache_repository = district_cache_repository
        self.taluka_cache_repository = taluka_cache_repository
        self.village_cache_repository = village_cache_repository

    # =========================================================
    # DISTRICTS
    # =========================================================

    async def get_districts(self) -> List[DistrictSchema]:

        cached_districts = (
            self.district_cache_repository.get_all()
        )

        if not cached_districts:
            print(
                "⚠️ No districts found in PostgreSQL cache"
            )
            return []

        print(
            "✅ Districts loaded from PostgreSQL cache"
        )

        return [
            DistrictSchema(
                district_code=d.district_code,
                district_name=d.district_name,
                state_code=d.state_code,
            )
            for d in cached_districts
        ]

    # =========================================================
    # TALUKAS
    # =========================================================

    async def get_talukas(
        self,
        district_code: str,
    ) -> List[TalukaSchema]:

        cached_talukas = (
            self.taluka_cache_repository.get_by_district(
                district_code
            )
        )

        if not cached_talukas:
            print(
                "⚠️ No talukas found in PostgreSQL cache "
                f"for district={district_code}"
            )
            return []

        print(
            "✅ Talukas loaded from PostgreSQL cache"
        )

        return [
            TalukaSchema(
                taluka_code=t.taluka_code,
                taluka_name=t.taluka_name,
                district_code=t.district_code,
            )
            for t in cached_talukas
        ]

    # =========================================================
    # VILLAGES
    # =========================================================

    async def get_villages(
        self,
        district_code: str,
        taluka_code: str,
    ) -> List[VillageSchema]:

        cached_villages = (
            self.village_cache_repository.get_by_taluka(
                district_code=district_code,
                taluka_code=taluka_code,
            )
        )

        if not cached_villages:
            print(
                "⚠️ No villages found in PostgreSQL cache "
                f"for district={district_code} "
                f"taluka={taluka_code}"
            )
            return []

        print(
            "✅ Villages loaded from PostgreSQL cache"
        )

        return [
            VillageSchema(
                village_code=v.village_code,
                village_name=v.village_name,
                taluka_code=v.taluka_code,
                gis_code=v.gis_code,
            )
            for v in cached_villages
        ]

    # =========================================================
    # GIS CODE
    # =========================================================

    async def resolve_village_gis_code(
        self,
        district_code: str,
        taluka_code: str,
        village_code: str,
    ) -> GISCodeResponse:

        villages = (
            self.village_cache_repository.get_by_taluka(
                district_code=district_code,
                taluka_code=taluka_code,
            )
        )

        for village in villages:

            if village.village_code == village_code:

                return GISCodeResponse(
                    village_code=village_code,
                    gis_code=village.gis_code,
                    state="Maharashtra",
                    is_valid=True,
                )

        return GISCodeResponse(
            village_code=village_code,
            gis_code="",
            state="Maharashtra",
            is_valid=False,
        )