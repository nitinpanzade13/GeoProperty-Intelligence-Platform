import asyncio
import time
from typing import Dict, Any

from app.services.village_service import VillageService
from app.services.village_map_service import VillageMapService
from app.core.logging import logger


class AdminSyncService:

    def __init__(
        self,
        village_service: VillageService,
        village_map_service: VillageMapService,
    ):
        self.village_service = village_service
        self.village_map_service = village_map_service

    async def sync_district(
        self,
        district_code: str,
    ) -> Dict[str, Any]:

        start = time.perf_counter()

        logger.info(
            "ADMIN SYNC STARTED: district=%s",
            district_code,
        )

        # --------------------------------------------------
        # 1. Get all talukas for district
        # --------------------------------------------------

        talukas = await self.village_service.get_talukas(
            district_code
        )

        logger.info(
            "District %s has %s talukas",
            district_code,
            len(talukas),
        )

        total_villages = 0
        successful_villages = 0
        failed_villages = []

        # --------------------------------------------------
        # 2. Process each taluka
        # --------------------------------------------------

        for taluka in talukas:

            logger.info(
                "Processing taluka %s - %s",
                taluka.taluka_code,
                taluka.taluka_name,
            )

            # --------------------------------------------------
            # 3. Get villages
            #
            # IMPORTANT:
            # VillageService saves villages into PostgreSQL
            # before returning them when needed.
            # --------------------------------------------------

            villages = await self.village_service.get_villages(
                district_code=district_code,
                taluka_code=taluka.taluka_code,
            )

            total_villages += len(villages)

            logger.info(
                "Taluka %s has %s villages",
                taluka.taluka_code,
                len(villages),
            )

            # --------------------------------------------------
            # 4. Process villages with controlled concurrency
            # --------------------------------------------------

            semaphore = asyncio.Semaphore(3)

            async def sync_village(village):

                async with semaphore:

                    try:

                        logger.info(
                            "Syncing village %s (%s)",
                            village.village_name,
                            village.gis_code,
                        )

                        geojson = (
                            await self.village_map_service.build_and_cache(
                                village.gis_code
                            )
                        )

                        logger.info(
                            "Village %s synced successfully: %s properties",
                            village.gis_code,
                            geojson.get("total_surveys", 0),
                        )

                        return {
                            "success": True,
                            "gis_code": village.gis_code,
                            "village_name": village.village_name,
                            "survey_count": geojson.get(
                                "total_surveys",
                                0,
                            ),
                        }

                    except Exception as exc:

                        logger.exception(
                            "Village sync failed: %s",
                            village.gis_code,
                        )

                        return {
                            "success": False,
                            "gis_code": village.gis_code,
                            "village_name": village.village_name,
                            "error": str(exc),
                        }

            results = await asyncio.gather(
                *[
                    sync_village(village)
                    for village in villages
                ]
            )

            for result in results:

                if result["success"]:
                    successful_villages += 1
                else:
                    failed_villages.append(result)

        # --------------------------------------------------
        # 5. Final result
        # --------------------------------------------------

        duration = time.perf_counter() - start

        logger.info(
            "ADMIN SYNC COMPLETED: district=%s duration=%.2fs",
            district_code,
            duration,
        )

        return {
            "district_code": district_code,
            "total_talukas": len(talukas),
            "total_villages": total_villages,
            "successful_villages": successful_villages,
            "failed_villages": len(failed_villages),
            "failures": failed_villages,
            "duration_seconds": round(duration, 2),
        }