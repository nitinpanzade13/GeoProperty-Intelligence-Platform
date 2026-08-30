from typing import Optional

from app.models.domain_models import Property
from app.schemas.property import (
    PropertyDetailsResponse,
    OwnerSchema,
    PolygonSchema,
)
from app.schemas.extent import (
    Point2DSchema,
    PlotExtentSchema,
)


class PropertyService:

    def __init__(self, repository):
        self.repository = repository

    async def get_property_details(
        self,
        gis_code: str,
        survey_number: str,
    ) -> Optional[PropertyDetailsResponse]:

        property_data: Optional[Property] = (
            await self.repository.get_property_details(
                gis_code=gis_code,
                survey_number=survey_number,
            )
        )

        if property_data is None:
            return None

        # -------------------------------------------------
        # Owners
        # -------------------------------------------------

        owners = [
            OwnerSchema(
                owner_name=owner.owner_name,
                khata_number=owner.khata_number,
                total_area=owner.total_area,
                pot_kharaba=owner.pot_kharaba,
            )
            for owner in property_data.owners
        ]

        # -------------------------------------------------
        # Polygon
        # -------------------------------------------------

        polygon = None

        if property_data.polygon is not None:

            polygon = PolygonSchema(
                polygon_id=property_data.polygon.polygon_id,
                points=[
                    Point2DSchema(
                        latitude=point.latitude,
                        longitude=point.longitude,
                    )
                    for point in property_data.polygon.points
                ],
                area_sq_meters=(
                    property_data.polygon.area_sq_meters
                ),
            )

        # -------------------------------------------------
        # Extent
        # -------------------------------------------------

        extent = None

        if property_data.extent is not None:

            extent = PlotExtentSchema(
                min_latitude=property_data.extent.min_latitude,
                min_longitude=property_data.extent.min_longitude,
                max_latitude=property_data.extent.max_latitude,
                max_longitude=property_data.extent.max_longitude,
            )

        # -------------------------------------------------
        # Response
        # -------------------------------------------------

        return PropertyDetailsResponse(
            property_id=property_data.property_id,
            survey_number=property_data.survey_number,
            area_sq_meters=property_data.area_sq_meters,
            plot_id=property_data.plot_id,
            gis_code=property_data.gis_code,
            owners=owners,
            polygon=polygon,
            extent=extent,
        )