from typing import Dict, Any, List


class GeoJsonBuilder:
    """
    Builds a GeoJSON FeatureCollection from property domain objects.
    """

    @staticmethod
    def build(
        gis_code: str,
        properties: List[Dict[str, Any]],
    ) -> Dict[str, Any]:

        features = []

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

        return {
            "type": "FeatureCollection",
            "gis_code": gis_code,
            "total_surveys": len(features),
            "features": features,
        }