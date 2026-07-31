import re
from typing import List, Tuple
from app.models.domain_models import Point2D, PlotExtent


class GeometryParser:
    """
    WKT Geometry Parser for GIS land record shapes.
    Converts WKT POLYGON and MULTIPOLYGON representations into strongly typed
    coordinate lists List[List[Point2D]] and calculates geographical extents.
    Never exposes raw WKT strings outside the provider layer.
    """

    @staticmethod
    def parse_wkt_to_coordinates(wkt_string: str) -> List[List[Point2D]]:
        if not wkt_string or not isinstance(wkt_string, str):
            return []

        wkt_clean = wkt_string.strip().upper()
        polygons: List[List[Point2D]] = []

        if wkt_clean.startswith("MULTIPOLYGON"):
            # Extract content inside outer MULTIPOLYGON parentheses
            polygon_matches = re.findall(r"\(\s*\(\s*([^()]+)\s*\)\s*\)", wkt_clean)
            if not polygon_matches:
                # Fallback regex for nested ring structures
                polygon_matches = re.findall(r"\(([^()]+)\)", wkt_clean)

            for poly_str in polygon_matches:
                pts = GeometryParser._parse_point_sequence(poly_str)
                if pts:
                  polygons.append(pts)

        elif wkt_clean.startswith("POLYGON"):
            poly_match = re.search(r"\(\s*\(\s*([^()]+)\s*\)\s*\)", wkt_clean)
            if not poly_match:
                poly_match = re.search(r"\(([^()]+)\)", wkt_clean)

            if poly_match:
                pts = GeometryParser._parse_point_sequence(poly_match.group(1))
                if pts:
                    polygons.append(pts)

        else:
            # Fallback for plain coordinate pairs "lng lat, lng lat"
            pts = GeometryParser._parse_point_sequence(wkt_clean)
            if pts:
                polygons.append(pts)

        return polygons

    @staticmethod
    def _parse_point_sequence(coord_str: str) -> List[Point2D]:
        points: List[Point2D] = []
        pairs = coord_str.split(",")

        for pair in pairs:
            clean_pair = pair.strip()
            if not clean_pair:
                continue
            parts = clean_pair.split()
            if len(parts) >= 2:
                try:
                    # In GIS WKT standards, order is typically (longitude, latitude)
                    lng = float(parts[0])
                    lat = float(parts[1])
                    points.append(Point2D(latitude=lat, longitude=lng))
                except ValueError:
                    continue
        return points

    @staticmethod
    def calculate_extent(polygons: List[List[Point2D]]) -> PlotExtent:
        if not polygons or not polygons[0]:
            return PlotExtent(
                min_latitude=18.5195,
                min_longitude=73.8567,
                max_latitude=18.5210,
                max_longitude=73.8582,
            )

        all_points = [pt for poly in polygons for pt in poly]
        lats = [pt.latitude for pt in all_points]
        lngs = [pt.longitude for pt in all_points]

        return PlotExtent(
            min_latitude=min(lats),
            min_longitude=min(lngs),
            max_latitude=max(lats),
            max_longitude=max(lngs),
        )
