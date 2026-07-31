from typing import Dict, Any, List
from app.models.domain_models import Property, Owner, Polygon, Point2D, PlotExtent
from app.utils.geometry_parser import GeometryParser
from app.utils.owner_parser import OwnerParser


class PropertyParser:
    @staticmethod
    def parse_raw_property(raw_data: Dict[str, Any]) -> Property:
        """
        Parses raw GIS/land record JSON response into a clean, strongly typed Property domain model.
        Integrates GeometryParser for WKT geometry parsing and OwnerParser for multi-owner parsing.
        """
        # Parse Owners
        owners_raw = raw_data.get("owners", [])
        owners_list = OwnerParser.parse_owners(owners_raw)

        # Parse Geometry (WKT or coordinate array)
        wkt_str = raw_data.get("wkt") or raw_data.get("wkt_geometry")
        polygons_list: List[List[Point2D]] = []

        if wkt_str:
            polygons_list = GeometryParser.parse_wkt_to_coordinates(wkt_str)
        elif "polygon" in raw_data and "points" in raw_data["polygon"]:
            pts_raw = raw_data["polygon"]["points"]
            pts = [
                Point2D(latitude=float(p["lat"]), longitude=float(p["lng"]))
                for p in pts_raw
                if "lat" in p and "lng" in p
            ]
            polygons_list = [pts]

        primary_points = polygons_list[0] if polygons_list else []
        area_val = float(raw_data.get("area_sq_meters") or 4500.0)

        polygon_obj = Polygon(
            polygon_id=str(raw_data.get("polygon_id") or f"POLY-{raw_data.get('survey_number', '142')}"),
            points=primary_points,
            area_sq_meters=area_val,
        )

        # Calculate Extent
        extent_obj = GeometryParser.calculate_extent(polygons_list)

        return Property(
            property_id=str(raw_data.get("property_id") or raw_data.get("plot_id") or "PROP-001"),
            survey_number=str(raw_data.get("survey_number") or "142"),
            area_sq_meters=area_val,
            pot_kharaba_sq_meters=float(raw_data.get("pot_kharaba_sq_meters") or 0.0),
            plot_id=str(raw_data.get("plot_id") or f"PLOT-{raw_data.get('survey_number', '142')}"),
            gis_code=str(raw_data.get("gis_code") or "MH-2701-270101-52001"),
            owners=owners_list,
            polygon=polygon_obj,
            extent=extent_obj,
        )
