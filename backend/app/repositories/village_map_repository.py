import asyncio
from typing import List, Dict

from app.repositories.survey_repository import SurveyRepository
from app.repositories.property_repository import PropertyRepository


class VillageMapRepository:
    """
    Downloads every survey polygon in parallel.
    """

    def __init__(
        self,
        survey_repository: SurveyRepository,
        property_repository: PropertyRepository,
    ):
        self.survey_repository = survey_repository
        self.property_repository = property_repository

    async def fetch_complete_village(self, gis_code: str) -> List[Dict]:

        surveys = await self.survey_repository.fetch_surveys(gis_code)

        semaphore = asyncio.Semaphore(20)

        async def fetch_one(survey):

            survey_number = (
                survey.survey_number
                if hasattr(survey, "survey_number")
                else str(survey)
            )

            async with semaphore:
                try:
                    property_data = await self.property_repository.fetch_property_details(
                        gis_code=gis_code,
                        survey_number=survey_number,
                    )

                    return {
                        "survey_number": survey_number,
                        "property": property_data,
                    }

                except Exception:
                    return None

        tasks = [fetch_one(survey) for survey in surveys]

        results = await asyncio.gather(*tasks)

        return [r for r in results if r is not None]