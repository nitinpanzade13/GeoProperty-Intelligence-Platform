from typing import List, Tuple

from shapely.geometry import Point, Polygon


Coordinate = Tuple[float, float]


class GeometryUtils:
    """
    GIS geometry helper utilities.
    """

    @staticmethod
    def point_in_polygon(
        point: Coordinate,
        polygon: List[Coordinate],
    ) -> bool:
        """
        Determine whether a point lies inside a polygon.

        Uses Shapely's robust geometry engine.

        Args:
            point:
                (longitude, latitude)

            polygon:
                List of (longitude, latitude)

        Returns:
            True if point is inside or on the boundary.
        """

        if len(polygon) < 3:
            return False

        polygon_geom = Polygon(polygon)
        point_geom = Point(point)

        # Covers returns True for points inside AND on the boundary.
        return polygon_geom.covers(point_geom)