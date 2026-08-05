from typing import Dict, Any, List

from app.repositories.village_map_repository import VillageMapRepository
from app.repositories.cache.village_cache_repository import VillageCacheRepository


class VillageMapService:
    """
    Builds a complete interactive village map as a GeoJSON FeatureCollection.
    Uses PostgreSQL cache whenever possible.
    """

    def __init__(
        self,
        repository: VillageMapRepository,
        cache_repository: VillageCacheRepository,
    ):
        self.repository = repository
        self.cache_repository = cache_repository

    async def get_complete_village_map(
        self,
        gis_code: str,
    ) -> Dict[str, Any]:

        # -----------------------------------------------------
        # STEP 1 : Check PostgreSQL Cache
        # -----------------------------------------------------

        cached = self.cache_repository.get_by_gis_code(gis_code)

        if cached:
            print(f"✅ Loaded village {gis_code} from PostgreSQL cache")

            return cached.geojson

        print(f"⬇️ Downloading village {gis_code} from Bhunaksha")

        # -----------------------------------------------------
        # STEP 2 : Generate GeoJSON
        # -----------------------------------------------------

        properties = await self.repository.fetch_complete_village(gis_code)

        features: List[Dict[str, Any]] = []

        for item in properties:

            property_obj = item["property"]

            if (
                property_obj.polygon is None
                or not property_obj.polygon.points
            ):
                continue

            coordinates = [
                [point.longitude, point.latitude]
                for point in property_obj.polygon.points
            ]

            # GeoJSON polygons must be closed
            if coordinates[0] != coordinates[-1]:
                coordinates.append(coordinates[0])

            features.append(
                {
                    "type": "Feature",
                    "properties": {
                        "survey_number": property_obj.survey_number,
                        "property_id": property_obj.property_id,
                        "plot_id": property_obj.plot_id,
                        "area_sq_meters": property_obj.area_sq_meters,
                    },
                    "geometry": {
                        "type": "Polygon",
                        "coordinates": [coordinates],
                    },
                }
            )

        geojson = {
            "type": "FeatureCollection",
            "gis_code": gis_code,
            "total_surveys": len(features),
            "features": features,
        }

        # -----------------------------------------------------
        # STEP 3 : Save to PostgreSQL
        # -----------------------------------------------------

        self.cache_repository.save(
            gis_code=gis_code,
            geojson=geojson,
        )

        print(f"💾 Saved village {gis_code} into PostgreSQL")

        return geojson