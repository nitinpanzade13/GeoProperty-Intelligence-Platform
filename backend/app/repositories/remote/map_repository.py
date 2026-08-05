from app.providers.base_provider import LandRecordsProvider
from app.models.domain_models import PlotExtent


class MapRepository:
    def __init__(self, provider: LandRecordsProvider):
        self.provider = provider

    async def fetch_plot_extent(
        self, gis_code: str, survey_number: str
    ) -> PlotExtent:
        return await self.provider.get_plot_extent(gis_code, survey_number)
