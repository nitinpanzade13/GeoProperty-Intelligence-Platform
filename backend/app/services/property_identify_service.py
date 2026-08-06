from typing import Optional, Dict, Any

from app.repositories.property_identify_repository import (
    PropertyIdentifyRepository,
)

from app.schemas.property_identify_response import (
    PropertyIdentifyResponse,
)


class PropertyIdentifyService:
    """
    Business logic for identifying a property
    from a map coordinate.
    """

    def __init__(
        self,
        repository: PropertyIdentifyRepository,
    ):
        self.repository = repository

    def identify_property(
        self,
        gis_code: str,
        latitude: float,
        longitude: float,
    ) -> Optional[Dict[str, Any]]:

        feature = self.repository.identify_property(
            gis_code=gis_code,
            latitude=latitude,
            longitude=longitude,
        )

        if feature is None:
            return None

        properties = feature.get("properties", {})

        return PropertyIdentifyResponse(
            survey_number=properties.get("survey_number"),
            property_id=properties.get("property_id"),
            plot_id=properties.get("plot_id"),
            area_sq_meters=properties.get("area_sq_meters"),
            owner_name=properties.get("owner_name"),
            khata_number=properties.get("khata_number"),
            geometry=feature.get("geometry"),
        )