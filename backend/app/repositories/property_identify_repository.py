from typing import Optional, Dict, Any, List

from app.repositories.cache.village_map_cache_repository import (
    VillageMapCacheRepository,
)
from app.utils.geometry import GeometryUtils


class PropertyIdentifyRepository:
    """
    Identifies the property containing a given coordinate
    using the cached village GeoJSON.
    """

    def __init__(
        self,
        cache_repository: VillageMapCacheRepository,
    ):
        self.cache_repository = cache_repository

    def identify_property(
        self,
        gis_code: str,
        latitude: float,
        longitude: float,
    ) -> Optional[Dict[str, Any]]:

        cache = self.cache_repository.get_village_map(gis_code)

        if cache is None:
            return None

        geojson = cache.geojson

        features = geojson.get("features", [])

        point = (longitude, latitude)

        for feature in features:

            geometry = feature.get("geometry")

            if geometry is None:
                continue

            if geometry.get("type") != "Polygon":
                continue

            coordinates = geometry.get("coordinates")

            if not coordinates:
                continue

            outer_ring = coordinates[0]

            polygon = [
                (coord[0], coord[1])
                for coord in outer_ring
            ]

            if GeometryUtils.point_in_polygon(
                point,
                polygon,
            ):
                return feature

        return None