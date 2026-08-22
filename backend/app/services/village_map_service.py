import time
from typing import Dict, Any

from app.builders.geojson_builder import GeoJsonBuilder

from app.repositories.village_map_repository import (
    VillageMapRepository,
)

from app.repositories.cache.village_map_cache_repository import (
    VillageMapCacheRepository,
)

from app.repositories.cache.property_cache_repository import (
    PropertyCacheRepository,
)

from app.core.logging import logger


class VillageMapService:
    """
    Village map service.

    IMPORTANT ARCHITECTURE:

        NORMAL USER
            ↓
        PostgreSQL Cache
            ↓
        Return cached data

        If data is not available:
            ↓
        DO NOT CALL BHUNAKSHA

    Admin synchronization uses:

        Admin
            ↓
        build_and_cache()
            ↓
        BhuNaksha
            ↓
        PostgreSQL
    """

    def __init__(
        self,
        repository: VillageMapRepository,
        cache_repository: VillageMapCacheRepository,
        property_cache_repository: PropertyCacheRepository,
    ):
        self.repository = repository
        self.cache_repository = cache_repository
        self.property_cache_repository = property_cache_repository

    # =========================================================
    # NORMAL USER
    # POSTGRESQL ONLY
    # =========================================================

    async def get_complete_village_map(
        self,
        gis_code: str,
    ) -> Dict[str, Any]:

        start = time.perf_counter()

        logger.info(
            "USER VILLAGE MAP REQUEST: gis_code=%s",
            gis_code,
        )

        # -----------------------------------------------------
        # 1. PostgreSQL cache
        # -----------------------------------------------------

        cached = self.cache_repository.get_village_map(
            gis_code
        )

        # -----------------------------------------------------
        # 2. Cache HIT
        # -----------------------------------------------------

        if cached:

            logger.info(
                "Village %s loaded from PostgreSQL cache",
                gis_code,
            )

            logger.info(
                "User response served from PostgreSQL in %.2f ms",
                (time.perf_counter() - start) * 1000,
            )

            return cached.geojson

        # -----------------------------------------------------
        # 3. Cache MISS
        #
        # VERY IMPORTANT:
        #
        # DO NOT call BhuNaksha here.
        #
        # Normal users are PostgreSQL-only.
        # -----------------------------------------------------

        logger.warning(
            "Village %s not available in PostgreSQL cache. "
            "BhuNaksha will NOT be called for normal user.",
            gis_code,
        )

        raise ValueError(
            "Village data is not available. "
            "Please ask an administrator to sync this village."
        )

    # =========================================================
    # ADMIN SYNC
    # BHUNAKSHA → POSTGRESQL
    # =========================================================

    async def build_and_cache(
        self,
        gis_code: str,
    ) -> Dict[str, Any]:

        logger.info(
            "ADMIN VILLAGE FETCH STARTED: gis_code=%s",
            gis_code,
        )

        try:

            # -------------------------------------------------
            # 1. Fetch complete village from BhuNaksha
            #
            # THIS METHOD MUST ONLY BE CALLED BY ADMIN SYNC.
            # -------------------------------------------------

            logger.info(
                "Fetching village %s from Maharashtra BhuNaksha",
                gis_code,
            )

            properties = (
                await self.repository.fetch_complete_village(
                    gis_code
                )
            )

            logger.info(
                "Fetched %s properties for village %s",
                len(properties),
                gis_code,
            )

            # -------------------------------------------------
            # 2. Save property + owner data into PostgreSQL
            # -------------------------------------------------

            saved_count = (
                self.property_cache_repository
                .upsert_properties(
                    properties
                )
            )

            logger.info(
                "Saved %s properties into PostgreSQL "
                "for village %s",
                saved_count,
                gis_code,
            )

            # -------------------------------------------------
            # 3. Build GeoJSON
            # -------------------------------------------------

            geojson = GeoJsonBuilder.build(
                gis_code=gis_code,
                properties=properties,
            )

            # -------------------------------------------------
            # 4. Save village map into PostgreSQL
            # -------------------------------------------------

            self.cache_repository.upsert_village_map(
                gis_code=gis_code,
                geojson=geojson,
                survey_count=geojson["total_surveys"],
            )

            logger.info(
                "Village %s successfully cached into PostgreSQL",
                gis_code,
            )

            logger.info(
                "ADMIN VILLAGE FETCH COMPLETED: gis_code=%s",
                gis_code,
            )

            return geojson

        except Exception as ex:

            logger.exception(
                "ADMIN VILLAGE FETCH FAILED: gis_code=%s",
                gis_code,
            )

            raise

    # =========================================================
    # ADMIN BACKGROUND REFRESH
    # =========================================================
    #
    # This method is intentionally kept separate from the
    # normal-user flow.
    #
    # If Admin wants to refresh already cached data,
    # AdminSyncService can call build_and_cache() directly.
    #
    # Therefore normal users never trigger this method.
    # =========================================================