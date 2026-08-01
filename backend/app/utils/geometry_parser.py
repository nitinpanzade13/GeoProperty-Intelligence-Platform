import re
from typing import List

from pyproj import Transformer

from app.models.domain_models import Point2D, PlotExtent


class GeometryParser:
    """
    Parses Bhunaksha WKT geometries.

    Bhunaksha returns WKT in a projected CRS (meters), not WGS84.

    This parser converts every coordinate to EPSG:4326 so Flutter/OpenStreetMap
    receives valid latitude/longitude coordinates.
    """

    # IMPORTANT:
    # Replace EPSG:32643 if your Bhunaksha installation uses another CRS.
    # Maharashtra Bhunaksha commonly uses UTM Zone 43N.
    _transformer = Transformer.from_crs(
        "EPSG:32643",
        "EPSG:4326",
        always_xy=True,
    )

    @staticmethod
    def parse_wkt_to_coordinates(wkt_string: str) -> List[List[Point2D]]:
        if not wkt_string:
            return []

        polygons: List[List[Point2D]] = []

        wkt = wkt_string.strip()

        if wkt.upper().startswith("MULTIPOLYGON"):

            matches = re.findall(
                r"\(\(\((.*?)\)\)\)",
                wkt,
                flags=re.DOTALL,
            )

            for match in matches:
                pts = GeometryParser._parse_point_sequence(match)
                if pts:
                    polygons.append(pts)

        elif wkt.upper().startswith("POLYGON"):

            match = re.search(
                r"\(\((.*?)\)\)",
                wkt,
                flags=re.DOTALL,
            )

            if match:
                pts = GeometryParser._parse_point_sequence(match.group(1))
                if pts:
                    polygons.append(pts)

        return polygons

    @staticmethod
    def _parse_point_sequence(coord_string: str) -> List[Point2D]:

        points: List[Point2D] = []

        for pair in coord_string.split(","):

            pair = pair.strip()

            if not pair:
                continue

            values = pair.split()

            if len(values) < 2:
                continue

            try:

                x = float(values[0])
                y = float(values[1])

                lon, lat = GeometryParser._transformer.transform(x, y)

                points.append(
                    Point2D(
                        latitude=lat,
                        longitude=lon,
                    )
                )

            except Exception:
                continue

        return points

    @staticmethod
    def calculate_extent(polygons: List[List[Point2D]]) -> PlotExtent:

        if not polygons:
            return PlotExtent(
                min_latitude=0,
                min_longitude=0,
                max_latitude=0,
                max_longitude=0,
            )

        all_points = [p for poly in polygons for p in poly]

        return PlotExtent(
            min_latitude=min(p.latitude for p in all_points),
            min_longitude=min(p.longitude for p in all_points),
            max_latitude=max(p.latitude for p in all_points),
            max_longitude=max(p.longitude for p in all_points),
        )