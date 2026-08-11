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
        village_map_cache_repository,
    ):
        self.village_service = village_service
        self.village_map_service = village_map_service
        self.village_map_cache_repository = village_map_cache_repository

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
        skipped_villages = 0
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
            # 4. Filter already completed villages
            #
            # If village exists in village_map_cache,
            # consider it successfully synced.
            # --------------------------------------------------

            pending_villages = []

            for village in villages:

                try:

                    cached = (
                        self.village_map_cache_repository
                        .get_village_map(village.gis_code)
                    )

                    if cached:

                        skipped_villages += 1

                        logger.info(
                            "Skipping already synced village: "
                            "%s (%s)",
                            village.village_name,
                            village.gis_code,
                        )

                        continue

                    pending_villages.append(village)

                except Exception as exc:

                    # If cache lookup itself fails,
                    # don't silently skip the village.
                    # Add it to pending so it can be processed.
                    logger.warning(
                        "Cache check failed for village %s: %s. "
                        "Processing village anyway.",
                        village.gis_code,
                        exc,
                    )

                    pending_villages.append(village)

            logger.info(
                "Taluka %s: total=%s, already_synced=%s, pending=%s",
                taluka.taluka_code,
                len(villages),
                len(villages) - len(pending_villages),
                len(pending_villages),
            )

            # --------------------------------------------------
            # Nothing to process for this taluka
            # --------------------------------------------------

            if not pending_villages:

                logger.info(
                    "Taluka %s already completely synced.",
                    taluka.taluka_code,
                )

                continue

            # --------------------------------------------------
            # 5. Process pending villages with controlled
            #    concurrency
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
                            "Village %s synced successfully: "
                            "%s properties",
                            village.gis_code,
                            geojson.get(
                                "total_surveys",
                                0,
                            ),
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

            # --------------------------------------------------
            # 6. Run pending villages
            # --------------------------------------------------

            results = await asyncio.gather(
                *[
                    sync_village(village)
                    for village in pending_villages
                ]
            )

            # --------------------------------------------------
            # 7. Process results
            # --------------------------------------------------

            for result in results:

                if result["success"]:

                    successful_villages += 1

                else:

                    failed_villages.append(result)

        # --------------------------------------------------
        # 8. Final result
        # --------------------------------------------------

        duration = time.perf_counter() - start

        logger.info(
            "ADMIN SYNC COMPLETED: district=%s "
            "duration=%.2fs "
            "total=%s "
            "skipped=%s "
            "successful=%s "
            "failed=%s",
            district_code,
            duration,
            total_villages,
            skipped_villages,
            successful_villages,
            len(failed_villages),
        )

        return {
            "district_code": district_code,
            "total_talukas": len(talukas),
            "total_villages": total_villages,
            "skipped_villages": skipped_villages,
            "successful_villages": successful_villages,
            "failed_villages": len(failed_villages),
            "pending_villages": (
                total_villages
                - skipped_villages
                - successful_villages
            ),
            "failures": failed_villages,
            "duration_seconds": round(duration, 2),
        }