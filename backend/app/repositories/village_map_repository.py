import asyncio
from typing import List, Dict

from app.repositories.remote.survey_repository import SurveyRepository
from app.repositories.remote.property_repository import PropertyRepository
from app.core.logging import logger
from app.core.config import settings


class VillageMapRepository:
    """
    Downloads every survey polygon with controlled concurrency.

    Concurrency is controlled here.
    HTTP retry/backoff is handled by GISHttpClient.
    """

    def __init__(
        self,
        survey_repository: SurveyRepository,
        property_repository: PropertyRepository,
    ):
        self.survey_repository = survey_repository
        self.property_repository = property_repository

    async def fetch_complete_village(
        self,
        gis_code: str,
    ) -> List[Dict]:

        # --------------------------------------------------
        # 1. Get all survey numbers for the village
        # --------------------------------------------------

        surveys = await self.survey_repository.fetch_surveys(
            gis_code
        )

        if not surveys:
            logger.warning(
                "No surveys found for village %s",
                gis_code,
            )
            return []

        # --------------------------------------------------
        # 2. Limit concurrent requests
        #
        # Never allow more than 3 survey requests
        # to BhuNaksha at the same time.
        # --------------------------------------------------

        max_concurrent = settings.MAX_PARALLEL_SURVEY_REQUESTS

        semaphore = asyncio.Semaphore(
            max_concurrent
        )

        logger.info(
            "Village %s: %s surveys found. "
            "Maximum concurrent requests: %s",
            gis_code,
            len(surveys),
            max_concurrent,
        )

        # --------------------------------------------------
        # 3. Fetch one survey
        #
        # No retry here.
        # GISHttpClient handles retry/backoff.
        # --------------------------------------------------

        async def fetch_one(survey):

            survey_number = (
                survey.survey_number
                if hasattr(survey, "survey_number")
                else str(survey)
            )

            async with semaphore:

                try:

                    logger.info(
                        "Fetching survey %s",
                        survey_number,
                    )

                    property_data = (
                        await self.property_repository
                        .fetch_property_details(
                            gis_code=gis_code,
                            survey_number=survey_number,
                        )
                    )

                    logger.info(
                        "Survey %s fetched successfully",
                        survey_number,
                    )

                    return {
                        "survey_number": survey_number,
                        "property": property_data,
                    }

                except Exception as ex:

                    logger.error(
                        "Survey %s failed: %s",
                        survey_number,
                        ex,
                    )

                    # Do not retry here.
                    # GISHttpClient already handles
                    # HTTP retries and backoff.
                    return None

        # --------------------------------------------------
        # 4. Process surveys in small batches
        # --------------------------------------------------

        results = []

        batch_size = max_concurrent

        for i in range(
            0,
            len(surveys),
            batch_size,
        ):

            batch = surveys[
                i:i + batch_size
            ]

            batch_start = i + 1
            batch_end = min(
                i + batch_size,
                len(surveys),
            )

            logger.info(
                "Processing survey batch %s-%s of %s",
                batch_start,
                batch_end,
                len(surveys),
            )

            batch_results = await asyncio.gather(
                *[
                    fetch_one(survey)
                    for survey in batch
                ]
            )

            successful = [
                result
                for result in batch_results
                if result is not None
            ]

            results.extend(successful)

            logger.info(
                "Batch %s-%s completed: "
                "%s/%s successful",
                batch_start,
                batch_end,
                len(successful),
                len(batch),
            )

            # --------------------------------------------------
            # Small cooldown between batches.
            #
            # This prevents a continuous burst of requests
            # against the external GIS service.
            # --------------------------------------------------

            if batch_end < len(surveys):

                await asyncio.sleep(1)

        # --------------------------------------------------
        # 5. Final summary
        # --------------------------------------------------

        failed_count = (
            len(surveys) - len(results)
        )

        logger.info(
            "Village %s completed: "
            "%s/%s surveys downloaded, "
            "%s failed",
            gis_code,
            len(results),
            len(surveys),
            failed_count,
        )

        return results