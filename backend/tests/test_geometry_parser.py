import unittest
from app.utils.geometry_parser import GeometryParser


class TestGeometryParser(unittest.TestCase):
    def test_parse_wkt_multipolygon(self):
        wkt = "MULTIPOLYGON (((73.8567 18.5204, 73.8575 18.5210, 73.8582 18.5201, 73.8570 18.5195, 73.8567 18.5204)))"
        coords = GeometryParser.parse_wkt_to_coordinates(wkt)

        self.assertEqual(len(coords), 1)
        self.assertEqual(len(coords[0]), 5)
        # Check first point lat/lng
        self.assertEqual(coords[0][0].latitude, 18.5204)
        self.assertEqual(coords[0][0].longitude, 73.8567)

    def test_parse_wkt_polygon(self):
        wkt = "POLYGON ((73.8567 18.5204, 73.8575 18.5210, 73.8567 18.5204))"
        coords = GeometryParser.parse_wkt_to_coordinates(wkt)

        self.assertEqual(len(coords), 1)
        self.assertEqual(len(coords[0]), 3)

    def test_calculate_extent(self):
        wkt = "POLYGON ((73.8567 18.5204, 73.8575 18.5210, 73.8582 18.5195, 73.8567 18.5204))"
        coords = GeometryParser.parse_wkt_to_coordinates(wkt)
        extent = GeometryParser.calculate_extent(coords)

        self.assertEqual(extent.min_latitude, 18.5195)
        self.assertEqual(extent.max_latitude, 18.5210)
        self.assertEqual(extent.min_longitude, 73.8567)
        self.assertEqual(extent.max_longitude, 73.8582)


if __name__ == "__main__":
    unittest.main()
