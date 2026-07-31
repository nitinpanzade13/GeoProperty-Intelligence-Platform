from app.repositories.property_repository import PropertyRepository
from app.schemas.property import (
    PropertyDetailsResponse,
    OwnerSchema,
    PolygonSchema,
)
from app.schemas.extent import Point2DSchema, PlotExtentSchema


class PropertyService:
    def __init__(self, repository: PropertyRepository):
        self.repository = repository

    async def get_property_details(
        self, gis_code: str, survey_number: str
    ) -> PropertyDetailsResponse:
        prop = await self.repository.fetch_property_details(gis_code, survey_number)

        owners_schema = [
            OwnerSchema(
                owner_name=o.owner_name,
                khata_number=o.khata_number,
                area_share_sq_meters=o.area_share_sq_meters,
                ownership_percentage=o.ownership_percentage,
            )
            for o in prop.owners
        ]

        polygon_schema = None
        if prop.polygon:
            polygon_schema = PolygonSchema(
                polygon_id=prop.polygon.polygon_id,
                points=[
                    Point2DSchema(latitude=p.latitude, longitude=p.longitude)
                    for p in prop.polygon.points
                ],
                area_sq_meters=prop.polygon.area_sq_meters,
            )

        extent_schema = None
        if prop.extent:
            extent_schema = PlotExtentSchema(
                min_latitude=prop.extent.min_latitude,
                min_longitude=prop.extent.min_longitude,
                max_latitude=prop.extent.max_latitude,
                max_longitude=prop.extent.max_longitude,
            )

        return PropertyDetailsResponse(
            property_id=prop.property_id,
            survey_number=prop.survey_number,
            area_sq_meters=prop.area_sq_meters,
            pot_kharaba_sq_meters=prop.pot_kharaba_sq_meters,
            plot_id=prop.plot_id,
            gis_code=prop.gis_code,
            owners=owners_schema,
            polygon=polygon_schema,
            extent=extent_schema,
        )
