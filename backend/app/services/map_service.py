from app.repositories.remote.map_repository import MapRepository
from app.schemas.extent import (
    PropertyExtentResponse,
    PlotExtentSchema,
    Point2DSchema,
)


class MapService:
    def __init__(self, repository: MapRepository):
        self.repository = repository

    async def get_plot_extent(
        self, gis_code: str, survey_number: str
    ) -> PropertyExtentResponse:
        extent = await self.repository.fetch_plot_extent(gis_code, survey_number)

        extent_schema = PlotExtentSchema(
            min_latitude=extent.min_latitude,
            min_longitude=extent.min_longitude,
            max_latitude=extent.max_latitude,
            max_longitude=extent.max_longitude,
        )

        bbox = [
            Point2DSchema(latitude=extent.min_latitude, longitude=extent.min_longitude),
            Point2DSchema(latitude=extent.max_latitude, longitude=extent.min_longitude),
            Point2DSchema(latitude=extent.max_latitude, longitude=extent.max_longitude),
            Point2DSchema(latitude=extent.min_latitude, longitude=extent.max_longitude),
        ]

        return PropertyExtentResponse(
            plot_id=f"PLOT-{survey_number}",
            extent=extent_schema,
            bounding_box=bbox,
        )
