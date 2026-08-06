import asyncio
import time
from typing import Dict, Any

from app.builders.geojson_builder import GeoJsonBuilder
from app.repositories.village_map_repository import VillageMapRepository
from app.repositories.cache.village_map_cache_repository import (
    VillageMapCacheRepository,
)

from app.core.logging import logger
from app.core.config import settings
from app.utils.cache_utils import is_cache_stale

from app.services.refresh_manager import RefreshManager

class VillageMapService:
    """
    Handles village GeoJSON generation.

    Flow:
        PostgreSQL Cache
              │
         Cache Hit?
          │       │
         Yes      No
          │        │
          ▼        ▼
    Check Stale   Download
          │        │
          ▼        ▼
    Background   Build GeoJSON
      Refresh         │
          │           ▼
          └────► Save Cache
                     │
                     ▼
                  Return
    """

    def __init__(
        self,
        repository: VillageMapRepository,
        cache_repository: VillageMapCacheRepository,
    ):
        self.repository = repository
        self.cache_repository = cache_repository

    async def get_complete_village_map(
        self,
        gis_code: str,
    ) -> Dict[str, Any]:

        start = time.perf_counter()

        # -------------------------------------------------
        # STEP 1 : PostgreSQL Cache
        # -------------------------------------------------

        cached = self.cache_repository.get_village_map(gis_code)

        if cached:

            logger.info(
                "Village %s loaded from PostgreSQL cache",
                gis_code,
            )

            # ---------------------------------------------
            # Cache Refresh Check
            # ---------------------------------------------

            if (
                settings.ENABLE_BACKGROUND_REFRESH
                and is_cache_stale(
                    cached.last_verified_at,
                    settings.CACHE_REFRESH_DAYS,
                )
            ):

                logger.info(
                    "Village %s cache is stale. Refresh scheduled.",
                    gis_code,
                )

                can_refresh = await RefreshManager.start_refresh(
                    gis_code
                )

                if can_refresh:

                    asyncio.create_task(
                        self.refresh_village_cache(gis_code)
                    )

                else:

                    logger.info(
                        "Refresh already running for %s",
                        gis_code,
                    )

            logger.info(
                "Response served in %.2f ms",
                (time.perf_counter() - start) * 1000,
            )

            return cached.geojson

        logger.info(
            "Downloading village %s from Maharashtra BhuNaksha",
            gis_code,
        )

        geojson = await self.build_and_cache(gis_code)

        logger.info(
            "Village generated in %.2f seconds",
            time.perf_counter() - start,
        )

        return geojson

    # ---------------------------------------------------------
    # Shared builder
    # ---------------------------------------------------------

    async def build_and_cache(
        self,
        gis_code: str,
    ) -> Dict[str, Any]:

        properties = await self.repository.fetch_complete_village(
            gis_code
        )

        geojson = GeoJsonBuilder.build(
            gis_code=gis_code,
            properties=properties,
        )

        self.cache_repository.upsert_village_map(
            gis_code=gis_code,
            geojson=geojson,
            survey_count=geojson["total_surveys"],
        )

        logger.info(
            "Village %s cached into PostgreSQL",
            gis_code,
        )

        return geojson

    # ---------------------------------------------------------
    # Background refresh
    # ---------------------------------------------------------

    async def refresh_village_cache(
        self,
        gis_code: str,
    ):

        try:

            logger.info(
                "Refreshing village %s in background...",
                gis_code,
            )

            await self.build_and_cache(gis_code)

            logger.info(
                "Background refresh completed for %s",
                gis_code,
            )

        except Exception as ex:

            logger.exception(
                "Background refresh failed for %s: %s",
                gis_code,
                ex,
            )
            
        finally:

            await RefreshManager.finish_refresh(
                gis_code
            )