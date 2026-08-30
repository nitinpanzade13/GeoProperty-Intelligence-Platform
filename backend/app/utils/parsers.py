from typing import Dict, Any, List

from app.models.domain_models import (
    Property,
    Polygon,
    Point2D,
    Owner,
)

from app.utils.geometry_parser import GeometryParser
from app.utils.owner_parser import OwnerParser


class PropertyParser:

    @staticmethod
    def parse_raw_property(
        raw_data: Dict[str, Any],
    ) -> Property:

        owners_raw = raw_data.get("owners", [])

        # Already parsed in maharashtra_provider.py
        if owners_raw and isinstance(owners_raw[0], Owner):
            owners_list = owners_raw
        else:
            owners_list = OwnerParser.parse_owners(
                owners_raw
            )

        # --------------------------------------------------
        # Geometry
        # --------------------------------------------------

        polygons: List[List[Point2D]] = []

        wkt = (
            raw_data.get("wkt")
            or raw_data.get("wkt_geometry")
        )

        if wkt:
            polygons = (
                GeometryParser.parse_wkt_to_coordinates(wkt)
            )

        elif "polygon" in raw_data:

            pts = raw_data["polygon"].get(
                "points",
                [],
            )

            polygons = [[
                Point2D(
                    latitude=float(p["lat"]),
                    longitude=float(p["lng"]),
                )
                for p in pts
            ]]

        # --------------------------------------------------
        # Basic validation
        # --------------------------------------------------

        plot_id = raw_data.get("plot_id")

        if not plot_id:
            raise ValueError("Missing plot_id")

        gis_code = raw_data.get("gis_code")

        if not gis_code:
            raise ValueError("Missing GIS code")

        # --------------------------------------------------
        # Polygon
        # --------------------------------------------------

        polygon = Polygon(
            polygon_id=str(
                raw_data.get("polygon_id")
                or plot_id
            ),
            points=(
                polygons[0]
                if polygons
                else []
            ),
            area_sq_meters=float(
                raw_data.get(
                    "area_sq_meters",
                    0.0,
                )
            ),
        )

        # --------------------------------------------------
        # Extent
        # --------------------------------------------------

        extent = GeometryParser.calculate_extent(
            polygons
        )

        # --------------------------------------------------
        # Property
        # --------------------------------------------------

        return Property(
            property_id=str(
                raw_data.get("property_id")
                or plot_id
            ),

            survey_number=str(
                raw_data["survey_number"]
            ),

            area_sq_meters=float(
                raw_data.get(
                    "area_sq_meters",
                    0.0,
                )
            ),

            plot_id=str(plot_id),

            gis_code=str(gis_code),

            owners=owners_list,

            polygon=polygon,

            extent=extent,
        )