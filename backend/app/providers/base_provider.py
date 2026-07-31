from abc import ABC, abstractmethod
from typing import List, Optional
from app.models.domain_models import (
    District,
    Taluka,
    Village,
    Survey,
    Property,
    PlotExtent,
)


class LandRecordsProvider(ABC):
    """
    Abstract interface for state land records & GIS providers.
    All external provider details (e.g. Maharashtra BhuNaksha APIs) must be
    encapsulated inside subclasses implementing this contract.
    """

    @abstractmethod
    async def get_districts(self) -> List[District]:
        """Fetch list of administrative districts."""
        pass

    @abstractmethod
    async def get_talukas(self, district_code: str) -> List[Taluka]:
        """Fetch list of talukas within a district."""
        pass

    @abstractmethod
    async def get_villages(self, district_code: str, taluka_code: str) -> List[Village]:
        """Fetch list of villages within a taluka."""
        pass

    @abstractmethod
    async def get_village_gis_code(
        self, district_code: str, taluka_code: str, village_code: str
    ) -> str:
        """Resolve state administrative codes into a unified GIS village code."""
        pass

    @abstractmethod
    async def get_survey_numbers(self, gis_code: str) -> List[Survey]:
        """Fetch available survey / plot numbers for a given village GIS code."""
        pass

    @abstractmethod
    async def get_plot_details(self, gis_code: str, survey_number: str) -> Property:
        """Fetch detailed property, owner, valuation, and polygon boundary data."""
        pass

    @abstractmethod
    async def get_plot_extent(
        self, gis_code: str, survey_number: str
    ) -> PlotExtent:
        """Fetch geographical bounding box extent (lat/lng bounds) for a plot."""
        pass
