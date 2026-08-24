import asyncio
import time
from typing import Dict, Any, List

from app.core.logging import logger

from app.repositories.remote.village_repository import (
    VillageRepository,
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

from app.repositories.cache.village_map_cache_repository import (
    VillageMapCacheRepository,
)

from app.repositories.cache.property_cache_repository import (
    PropertyCacheRepository,
)

from app.services.village_map_service import VillageMapService

from app.core.config import settings

from app.services.admin_sync_registry import (
    AdminSyncRegistry,
    admin_sync_registry,
)

class AdminSyncService:
    """
    Admin-only BhuNaksha synchronization service.

    IMPORTANT ARCHITECTURE
    =======================

    NORMAL USER
        |
        v
    PostgreSQL
        |
        v
    VillageService / VillageMapService
        |
        v
    Return cached data

    ADMIN
        |
        v
    AdminSyncService
        |
        v
    Maharashtra BhuNaksha
        |
        v
    PostgreSQL


    CONCURRENCY
    ===========

    Maximum 10 villages are processed concurrently.

    Inside each village:

        VillageMapRepository
                |
                v
        Maximum 3 survey requests concurrently.


    RESUME BEHAVIOUR
    ================

    Normal sync:

        Already cached village
                |
                v
             SKIP

        Missing village
                |
                v
             FETCH


    Therefore, if an admin starts a district sync and the process
    stops after 100 villages, starting the same sync again will
    skip those already stored villages and continue with the
    remaining villages.

    FORCE REFRESH
    =============

    If force_refresh=True:

        Existing village
                |
                v
        Fetch again from BhuNaksha
                |
                v
        Replace PostgreSQL cache

    This is intended for the admin's "Refresh / Refetch" action.
    """

    MAX_PARALLEL_VILLAGES = settings.MAX_PARALLEL_VILLAGE_REQUESTS

    def __init__(
        self,
        village_repository: VillageRepository,
        district_cache_repository: DistrictCacheRepository,
        taluka_cache_repository: TalukaCacheRepository,
        village_cache_repository: VillageCacheRepository,
        property_cache_repository: PropertyCacheRepository,
        village_map_cache_repository: VillageMapCacheRepository,
        village_map_service: VillageMapService,

    ):
        self.village_repository = village_repository

        self.district_cache_repository = (
            district_cache_repository
        )

        self.taluka_cache_repository = (
            taluka_cache_repository
        )

        self.village_cache_repository = (
            village_cache_repository
        )

        self.property_cache_repository = (
            property_cache_repository
        )

        self.village_map_cache_repository = (
            village_map_cache_repository
        )

        self.village_map_service = village_map_service

        # ---------------------------------------------------------
        # Active district synchronizations
        #
        # Keeps track of districts currently being synchronized.
        # This prevents duplicate sync requests for the same district.
        # ---------------------------------------------------------

        self._active_district_syncs: set[str] = set()

        self._active_taluka_syncs: set[str] = set()

        self._active_village_syncs: set[str] = set()

    # =========================================================
    # ASYNC DISTRICT SYNC
    # =========================================================

    def start_district_sync(
        self,
        district_code: str,
        force_refresh: bool = False,
    ) -> Dict[str, Any]:
        """
        Start a district synchronization in the background.

        IMPORTANT:
        This method returns immediately.

        The actual synchronization continues in an asyncio task.
        """

        district_code = str(
            district_code
        ).strip()

        if not district_code:
            return {
                "success": False,
                "sync_status": "not_synced",
                "sync_in_progress": False,
                "message": "District code is required.",
            }

        # -----------------------------------------------------
        # Prevent duplicate jobs globally.
        # -----------------------------------------------------

        if admin_sync_registry.is_running(
            district_code
        ):
            existing = admin_sync_registry.get(
                district_code
            )

            return {
                **(
                    existing
                    or {}
                ),
                "success": True,
                "already_running": True,
            }

        # -----------------------------------------------------
        # Register job BEFORE starting task.
        # -----------------------------------------------------

        job = admin_sync_registry.start(
            district_code=district_code,
            force_refresh=force_refresh,
        )

        # -----------------------------------------------------
        # Start actual synchronization in background.
        # -----------------------------------------------------

        asyncio.create_task(
            self._run_district_sync_background(
                district_code=district_code,
                force_refresh=force_refresh,
            )
        )

        return {
            **job,
            "success": True,
            "already_running": False,
        }

    async def _run_district_sync_background(
        self,
        district_code: str,
        force_refresh: bool = False,
    ):
        try:
            logger.info(
                "BACKGROUND DISTRICT SYNC STARTED: %s",
                district_code,
            )

            result = await self.sync_district(
                district_code=district_code,
                force_refresh=force_refresh,
            )

            admin_sync_registry.finish(
                district_code,
                result,
            )

            logger.info(
                "BACKGROUND DISTRICT SYNC FINISHED: "
                "district=%s status=%s",
                district_code,
                admin_sync_registry.get(
                    district_code
                ).get("sync_status"),
            )

        except Exception as exc:
            logger.exception(
                "BACKGROUND DISTRICT SYNC FAILED: "
                "district=%s",
                district_code,
            )

            admin_sync_registry.fail(
                district_code,
                str(exc),
            )

    def get_district_sync_status(
        self,
        district_code: str,
    ) -> Dict[str, Any]:

        district_code = str(
            district_code
        ).strip()

        job = admin_sync_registry.get(
            district_code
        )

        if job:
            return job

        return {
            "success": True,
            "district_code": district_code,
            "sync_status": "not_synced",
            "sync_in_progress": False,
            "total_talukas": 0,
            "total_villages": 0,
            "processed_villages": 0,
            "skipped_villages": 0,
            "successful_villages": 0,
            "failed_villages": 0,
            "pending_villages": 0,
            "progress_percent": 0,
            "message": "No active synchronization job.",
        }

    # =========================================================
    # LOCATION DATA
    # =========================================================

    async def _ensure_talukas(
        self,
        district_code: str,
    ) -> List[Any]:
        """
        Admin Taluka synchronization.

        IMPORTANT:
        Always fetch the complete Taluka list from BhuNaksha
        during an Admin district sync.

        We must NOT rely on PostgreSQL existing Talukas because
        the database may contain only a partial list.

        Example:

            PostgreSQL:
                04 / 09
                04 / 10
                04 / 11

            BhuNaksha:
                04 / 01
                04 / 02
                ...
                04 / 13

        The remote list is merged into PostgreSQL using the
        Taluka cache repository.

        Existing Talukas are updated.
        Missing Talukas are inserted.
        Talukas belonging to other districts are untouched.
        """

        logger.info(
            "ADMIN: Fetching complete Taluka list from BhuNaksha: "
            "district=%s",
            district_code,
        )

        # ---------------------------------------------------------
        # 1. ALWAYS fetch the authoritative Taluka list
        #    from BhuNaksha.
        # ---------------------------------------------------------

        remote_talukas = (
            await self.village_repository.fetch_talukas(
                district_code
            )
        )

        if not remote_talukas:
            logger.warning(
                "No Talukas returned from BhuNaksha: "
                "district=%s",
                district_code,
            )

            # Do NOT destroy existing PostgreSQL data.
            # Return whatever is already present.
            return (
                self.taluka_cache_repository
                .get_by_district(district_code)
            )

        # ---------------------------------------------------------
        # 2. Convert remote records to database models
        # ---------------------------------------------------------

        from app.database.models.taluka import Taluka

        taluka_models = [
            Taluka(
                taluka_code=t.taluka_code,
                taluka_name=t.taluka_name,
                district_code=t.district_code,
            )
            for t in remote_talukas
        ]

        # ---------------------------------------------------------
        # 3. MERGE into PostgreSQL
        #
        # With the new composite PK:
        #
        #     (district_code, taluka_code)
        #
        # the same Taluka code can safely exist in
        # multiple districts.
        # ---------------------------------------------------------

        self.taluka_cache_repository.save_all(
            taluka_models
        )

        logger.info(
            "ADMIN: Taluka synchronization completed: "
            "district=%s remote_talukas=%s",
            district_code,
            len(remote_talukas),
        )

        # ---------------------------------------------------------
        # 4. Return the COMPLETE updated list
        # ---------------------------------------------------------

        talukas = (
            self.taluka_cache_repository
            .get_by_district(district_code)
        )

        logger.info(
            "ADMIN: PostgreSQL now contains %s Talukas "
            "for district=%s",
            len(talukas),
            district_code,
        )

        return talukas

    async def _ensure_villages(
        self,
        district_code: str,
        taluka_code: str,
    ) -> List[Any]:
        """
        Get villages from PostgreSQL.

        If missing, Admin fetches them from BhuNaksha
        and saves them into PostgreSQL.
        """

        villages = (
            self.village_cache_repository
            .get_by_taluka(
                district_code=district_code,
                taluka_code=taluka_code,
            )
        )

        if villages:
            logger.info(
                "Villages loaded from PostgreSQL: "
                "district=%s taluka=%s count=%s",
                district_code,
                taluka_code,
                len(villages),
            )

            return villages

        logger.info(
            "Villages not found in PostgreSQL. "
            "Admin fetching from BhuNaksha: "
            "district=%s taluka=%s",
            district_code,
            taluka_code,
        )

        remote_villages = (
            await self.village_repository.fetch_villages(
                district_code=district_code,
                taluka_code=taluka_code,
            )
        )

        if not remote_villages:
            logger.warning(
                "No villages returned from BhuNaksha: "
                "district=%s taluka=%s",
                district_code,
                taluka_code,
            )

            return []

        from app.database.models.village import Village

        self.village_cache_repository.save_all(
            [
                Village(
                    village_code=v.village_code,
                    village_name=v.village_name,
                    taluka_code=v.taluka_code,
                    district_code=v.district_code,
                    gis_code=v.gis_code,
                )
                for v in remote_villages
            ]
        )

        logger.info(
            "Saved %s villages to PostgreSQL: "
            "district=%s taluka=%s",
            len(remote_villages),
            district_code,
            taluka_code,
        )

        return (
            self.village_cache_repository
            .get_by_taluka(
                district_code=district_code,
                taluka_code=taluka_code,
            )
        )

    # =========================================================
    # CHECK WHETHER VILLAGE IS ALREADY SYNCHRONIZED
    # =========================================================

    def _is_village_synced(
        self,
        gis_code: str,
    ) -> bool:
        """
        A village is considered synchronized when its complete
        village map exists in PostgreSQL.

        This is the checkpoint used for resume behaviour.
        """

        cached = (
            self.village_map_cache_repository
            .get_village_map(gis_code)
        )

        return cached is not None

    # =========================================================
    # SINGLE VILLAGE SYNC
    # =========================================================

    async def _sync_single_village(
        self,
        village,
        semaphore: asyncio.Semaphore,
        force_refresh: bool = False,
        district_code: str | None = None,
    ) -> Dict[str, Any]:

        async with semaphore:

            gis_code = village.gis_code

            try:

                # -------------------------------------------------
                # RESUME / SKIP
                # -------------------------------------------------

                if (
                    not force_refresh
                    and self._is_village_synced(gis_code)
                ):

                    cached = (
                        self.village_map_cache_repository
                        .get_village_map(gis_code)
                    )

                    survey_count = (
                        cached.survey_count
                        if cached
                        else 0
                    )

                    property_count = (
                        self.property_cache_repository
                        .count_by_gis_code(gis_code)
                    )

                    logger.info(
                        "SKIPPING ALREADY SYNCED VILLAGE: "
                        "village=%s gis_code=%s",
                        village.village_name,
                        gis_code,
                    )

                    result = {
                        "success": True,
                        "skipped": True,
                        "gis_code": gis_code,
                        "village_name": village.village_name,
                        "property_count": property_count,
                        "survey_count": survey_count,
                    }

                    if district_code:
                        admin_sync_registry.record_village(
                            district_code,
                            result,
                        )

                    return result

                # -------------------------------------------------
                # FETCH / REFRESH
                # -------------------------------------------------

                if force_refresh:

                    logger.info(
                        "FORCE REFRESH STARTED: "
                        "village=%s gis_code=%s",
                        village.village_name,
                        gis_code,
                    )

                else:

                    logger.info(
                        "ADMIN SYNC STARTED: "
                        "village=%s gis_code=%s",
                        village.village_name,
                        gis_code,
                    )

                start = time.perf_counter()

                geojson = (
                    await self.village_map_service
                    .build_and_cache(
                        gis_code
                    )
                )

                property_count = (
                    self.property_cache_repository
                    .count_by_gis_code(
                        gis_code
                    )
                )

                survey_count = geojson.get(
                    "total_surveys",
                    0,
                )

                duration = (
                    time.perf_counter() - start
                )

                logger.info(
                    "ADMIN VILLAGE SYNC COMPLETED: "
                    "village=%s gis_code=%s "
                    "properties=%s surveys=%s "
                    "duration=%.2fs",
                    village.village_name,
                    gis_code,
                    property_count,
                    survey_count,
                    duration,
                )

                result = {
                    "success": True,
                    "skipped": False,
                    "gis_code": gis_code,
                    "village_name": village.village_name,
                    "property_count": property_count,
                    "survey_count": survey_count,
                    "duration_seconds": round(
                        duration,
                        2,
                    ),
                }

                if district_code:
                    admin_sync_registry.record_village(
                        district_code,
                        result,
                    )
                return result

            except Exception as ex:

                logger.exception(
                    "ADMIN VILLAGE SYNC FAILED: "
                    "village=%s gis_code=%s",
                    village.village_name,
                    gis_code,
                )

                result = {
                    "success": False,
                    "skipped": False,
                    "gis_code": gis_code,
                    "village_name": village.village_name,
                    "property_count": 0,
                    "survey_count": 0,
                    "error": str(ex),
                }

                if district_code:
                    admin_sync_registry.record_village(
                        district_code,
                        result,
                    )
                return result

    # =========================================================
    # DISTRICT SYNC
    # =========================================================

    async def sync_district(
        self,
        district_code: str,
        force_refresh: bool = False,
    ) -> Dict[str, Any]:

        start = time.perf_counter()

        # ---------------------------------------------------------
        # Prevent duplicate district synchronization
        # ---------------------------------------------------------

        if district_code in self._active_district_syncs:

            logger.warning(
                "ADMIN DISTRICT SYNC ALREADY IN PROGRESS: "
                "district=%s",
                district_code,
            )

            return {
                "success": False,
                "sync_in_progress": True,
                "district_code": district_code,
                "message": (
                    f"District {district_code} synchronization "
                    "is already in progress."
                ),
            }

        # ---------------------------------------------------------
        # Mark district as active BEFORE doing any network work
        # ---------------------------------------------------------

        self._active_district_syncs.add(
            district_code
        )

        try:

            logger.info(
                "=================================================="
            )

            logger.info(
                "ADMIN DISTRICT SYNC STARTED: district=%s "
                "force_refresh=%s",
                district_code,
                force_refresh,
            )

            # ---------------------------------------------------------
            # 1. Get talukas
            # ---------------------------------------------------------

            talukas = await self._ensure_talukas(
                district_code
            )

            if not talukas:

                return {
                    "success": False,
                    "sync_in_progress": False,
                    "district_code": district_code,
                    "message": "No talukas found for district",
                    "total_talukas": 0,
                    "total_villages": 0,
                    "skipped_villages": 0,
                    "successful_villages": 0,
                    "failed_villages": 0,
                    "pending_villages": 0,
                    "failed": [],
                }

            # ---------------------------------------------------------
            # 2. Get villages from every taluka
            # ---------------------------------------------------------

            villages = []

            for taluka in talukas:

                try:

                    taluka_villages = (
                        await self._ensure_villages(
                            district_code=district_code,
                            taluka_code=taluka.taluka_code,
                        )
                    )

                    villages.extend(
                        taluka_villages
                    )

                except Exception:

                    logger.exception(
                        "Failed to load villages: "
                        "district=%s taluka=%s",
                        district_code,
                        taluka.taluka_code,
                    )

            if not villages:

                return {
                    "success": False,
                    "sync_in_progress": False,
                    "district_code": district_code,
                    "message": "No villages found for district",
                    "total_talukas": len(talukas),
                    "total_villages": 0,
                    "skipped_villages": 0,
                    "successful_villages": 0,
                    "failed_villages": 0,
                    "pending_villages": 0,
                    "failed": [],
                }

            # ---------------------------------------------------------
            # 3. Maximum concurrent villages
            # ---------------------------------------------------------

            semaphore = asyncio.Semaphore(
                self.MAX_PARALLEL_VILLAGES
            )

            logger.info(
                "District %s: %s villages found. "
                "Maximum concurrent villages: %s",
                district_code,
                len(villages),
                self.MAX_PARALLEL_VILLAGES,
            )

            # ---------------------------------------------------------
            # 4. Create tasks
            # ---------------------------------------------------------

            admin_sync_registry.update_totals(
                district_code,
                total_talukas=len(talukas),
                total_villages=len(villages),
            )

            tasks = [
                self._sync_single_village(
                    village=village,
                    semaphore=semaphore,
                    force_refresh=force_refresh,
                    district_code=district_code,
                )
                for village in villages
            ]

            # ---------------------------------------------------------
            # 5. Execute
            # ---------------------------------------------------------

            results = await asyncio.gather(
                *tasks
            )

            # ---------------------------------------------------------
            # 6. Process results
            # ---------------------------------------------------------

            successful = [
                result
                for result in results
                if result["success"]
                and not result.get("skipped", False)
            ]

            skipped = [
                result
                for result in results
                if result["success"]
                and result.get("skipped", False)
            ]

            failed = [
                result
                for result in results
                if not result["success"]
            ]

            duration = (
                time.perf_counter() - start
            )

            # ---------------------------------------------------------
            # 7. Final result
            # ---------------------------------------------------------

            result = {
                "success": len(failed) == 0,
                "sync_in_progress": False,
                "district_code": district_code,
                "total_talukas": len(talukas),
                "total_villages": len(villages),
                "skipped_villages": len(skipped),
                "successful_villages": len(successful),
                "failed_villages": len(failed),
                "pending_villages": len(failed),
                "force_refresh": force_refresh,
                "failed": failed,
                "duration_seconds": round(
                    duration,
                    2,
                ),
            }

            logger.info(
                "=================================================="
            )

            logger.info(
                "ADMIN DISTRICT SYNC COMPLETED: "
                "district=%s "
                "total=%s "
                "skipped=%s "
                "successful=%s "
                "failed=%s "
                "duration=%.2fs",
                district_code,
                len(villages),
                len(skipped),
                len(successful),
                len(failed),
                duration,
            )

            logger.info(
                "=================================================="
            )

            return result

        finally:

            # ---------------------------------------------------------
            # ALWAYS release the district lock
            #
            # This executes even when:
            # - BhuNaksha fails
            # - database fails
            # - an exception occurs
            # - the method returns early
            # ---------------------------------------------------------

            self._active_district_syncs.discard(
                district_code
            )

            logger.info(
                "ADMIN DISTRICT SYNC LOCK RELEASED: "
                "district=%s",
                district_code,
            )            

    # =========================================================
    # TALUKA SYNC
    # =========================================================

    async def sync_taluka(
        self,
        district_code: str,
        taluka_code: str,
        force_refresh: bool = False,
    ) -> Dict[str, Any]:

        start = time.perf_counter()

        # ---------------------------------------------------------
        # Unique key for taluka
        #
        # district_code is included because taluka_code alone
        # should not be assumed globally unique.
        # ---------------------------------------------------------

        sync_key = (
            f"{district_code}:{taluka_code}"
        )

        # ---------------------------------------------------------
        # Prevent duplicate taluka synchronization
        # ---------------------------------------------------------

        if sync_key in self._active_taluka_syncs:

            logger.warning(
                "ADMIN TALUKA SYNC ALREADY IN PROGRESS: "
                "district=%s taluka=%s",
                district_code,
                taluka_code,
            )

            return {
                "success": False,
                "sync_in_progress": True,
                "district_code": district_code,
                "taluka_code": taluka_code,
                "message": (
                    f"Taluka {taluka_code} synchronization "
                    "is already in progress."
                ),
            }

        self._active_taluka_syncs.add(
            sync_key
        )

        try:

            logger.info(
                "ADMIN TALUKA SYNC STARTED: "
                "district=%s taluka=%s force_refresh=%s",
                district_code,
                taluka_code,
                force_refresh,
            )

            # ---------------------------------------------------------
            # 1. Get villages
            # ---------------------------------------------------------

            villages = await self._ensure_villages(
                district_code=district_code,
                taluka_code=taluka_code,
            )

            if not villages:

                return {
                    "success": False,
                    "sync_in_progress": False,
                    "district_code": district_code,
                    "taluka_code": taluka_code,
                    "message": "No villages found for taluka",
                    "total_villages": 0,
                    "skipped_villages": 0,
                    "successful_villages": 0,
                    "failed_villages": 0,
                    "pending_villages": 0,
                    "failed": [],
                }

            # ---------------------------------------------------------
            # 2. Village concurrency
            # ---------------------------------------------------------

            semaphore = asyncio.Semaphore(
                self.MAX_PARALLEL_VILLAGES
            )

            logger.info(
                "Taluka %s: %s villages found. "
                "Maximum concurrent villages: %s",
                taluka_code,
                len(villages),
                self.MAX_PARALLEL_VILLAGES,
            )

            # ---------------------------------------------------------
            # 3. Create tasks
            # ---------------------------------------------------------

            tasks = [
                self._sync_single_village(
                    village=village,
                    semaphore=semaphore,
                    force_refresh=force_refresh,
                )
                for village in villages
            ]

            # ---------------------------------------------------------
            # 4. Execute
            # ---------------------------------------------------------

            results = await asyncio.gather(
                *tasks
            )

            # ---------------------------------------------------------
            # 5. Process results
            # ---------------------------------------------------------

            successful = [
                result
                for result in results
                if result["success"]
                and not result.get("skipped", False)
            ]

            skipped = [
                result
                for result in results
                if result["success"]
                and result.get("skipped", False)
            ]

            failed = [
                result
                for result in results
                if not result["success"]
            ]

            duration = (
                time.perf_counter() - start
            )

            logger.info(
                "ADMIN TALUKA SYNC COMPLETED: "
                "district=%s taluka=%s "
                "total=%s skipped=%s "
                "successful=%s failed=%s",
                district_code,
                taluka_code,
                len(villages),
                len(skipped),
                len(successful),
                len(failed),
            )

            return {
                "success": len(failed) == 0,
                "sync_in_progress": False,
                "district_code": district_code,
                "taluka_code": taluka_code,
                "total_villages": len(villages),
                "skipped_villages": len(skipped),
                "successful_villages": len(successful),
                "failed_villages": len(failed),
                "pending_villages": len(failed),
                "force_refresh": force_refresh,
                "failed": failed,
                "duration_seconds": round(
                    duration,
                    2,
                ),
            }

        finally:

            # ---------------------------------------------------------
            # Always release taluka lock
            # ---------------------------------------------------------

            self._active_taluka_syncs.discard(
                sync_key
            )

            logger.info(
                "ADMIN TALUKA SYNC LOCK RELEASED: "
                "district=%s taluka=%s",
                district_code,
                taluka_code,
            )

    # =========================================================
    # SINGLE VILLAGE SYNC
    # =========================================================

    async def sync_village(
        self,
        gis_code: str,
        force_refresh: bool = False,
    ) -> Dict[str, Any]:

        # ---------------------------------------------------------
        # Prevent duplicate village synchronization
        # ---------------------------------------------------------

        if gis_code in self._active_village_syncs:

            logger.warning(
                "ADMIN VILLAGE SYNC ALREADY IN PROGRESS: "
                "gis_code=%s",
                gis_code,
            )

            return {
                "success": False,
                "sync_in_progress": True,
                "gis_code": gis_code,
                "message": (
                    f"Village {gis_code} synchronization "
                    "is already in progress."
                ),
            }

        self._active_village_syncs.add(
            gis_code
        )

        try:

            logger.info(
                "ADMIN SINGLE VILLAGE SYNC STARTED: "
                "gis_code=%s force_refresh=%s",
                gis_code,
                force_refresh,
            )

            # ---------------------------------------------------------
            # If already synced and this is normal sync,
            # return without calling BhuNaksha.
            # ---------------------------------------------------------

            if (
                not force_refresh
                and self._is_village_synced(
                    gis_code
                )
            ):

                cached = (
                    self.village_map_cache_repository
                    .get_village_map(gis_code)
                )

                property_count = (
                    self.property_cache_repository
                    .count_by_gis_code(gis_code)
                )

                return {
                    "success": True,
                    "sync_in_progress": False,
                    "skipped": True,
                    "gis_code": gis_code,
                    "property_count": property_count,
                    "survey_count": (
                        cached.survey_count
                        if cached
                        else 0
                    ),
                    "message": (
                        "Village already synchronized"
                    ),
                }

            # ---------------------------------------------------------
            # Fetch and cache complete village data
            # ---------------------------------------------------------

            geojson = (
                await self.village_map_service
                .build_and_cache(
                    gis_code
                )
            )

            # ---------------------------------------------------------
            # Get property count
            # ---------------------------------------------------------

            property_count = (
                self.property_cache_repository
                .count_by_gis_code(
                    gis_code
                )
            )

            logger.info(
                "ADMIN VILLAGE SYNC COMPLETED: "
                "gis_code=%s",
                gis_code,
            )

            return {
                "success": True,
                "sync_in_progress": False,
                "skipped": False,
                "gis_code": gis_code,
                "property_count": property_count,
                "survey_count": geojson.get(
                    "total_surveys",
                    0,
                ),
                "force_refresh": force_refresh,
            }

        except Exception as ex:

            logger.exception(
                "ADMIN VILLAGE SYNC FAILED: "
                "gis_code=%s",
                gis_code,
            )

            return {
                "success": False,
                "sync_in_progress": False,
                "skipped": False,
                "gis_code": gis_code,
                "property_count": 0,
                "survey_count": 0,
                "error": str(ex),
                "force_refresh": force_refresh,
            }

        finally:

            # ---------------------------------------------------------
            # Always release village lock
            # ---------------------------------------------------------

            self._active_village_syncs.discard(
                gis_code
            )

            logger.info(
                "ADMIN VILLAGE SYNC LOCK RELEASED: "
                "gis_code=%s",
                gis_code,
            )