from typing import List
from app.providers.base_provider import LandRecordsProvider
from app.models.domain_models import Survey


class SurveyRepository:
    def __init__(self, provider: LandRecordsProvider):
        self.provider = provider

    async def fetch_surveys(self, gis_code: str) -> List[Survey]:
        return await self.provider.get_survey_numbers(gis_code)
