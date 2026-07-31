from app.providers.base_provider import LandRecordsProvider
from app.models.domain_models import Property


class PropertyRepository:
    def __init__(self, provider: LandRecordsProvider):
        self.provider = provider

    async def fetch_property_details(
        self, gis_code: str, survey_number: str
    ) -> Property:
        return await self.provider.get_plot_details(gis_code, survey_number)
