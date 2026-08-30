import unittest

from app.utils.parsers import PropertyParser


class TestPropertyParser(unittest.TestCase):

    def test_parse_raw_property_multi_owner(self):
        raw_data = {
            "property_id": "PROP-999",
            "survey_number": "142",
            "area_sq_meters": 5000.0,
            "plot_id": "PLOT-142",
            "gis_code": "MH-2701-270101-52001",
            "owners": [
                {
                    "name": "Owner One",
                    "khata_no": "KH-101",
                    "total_area": 0.9800,
                    "pot_kharaba": 0.0000,
                },
                {
                    "name": "Owner Two",
                    "khata_no": "KH-102",
                    "total_area": 0.5000,
                    "pot_kharaba": 0.0800,
                },
            ],
            "polygon": {
                "polygon_id": "POLY-142",
                "area_sq_meters": 5000.0,
                "points": [
                    {
                        "lat": 18.5204,
                        "lng": 73.8567,
                    },
                    {
                        "lat": 18.5210,
                        "lng": 73.8575,
                    },
                ],
            },
            "extent": {
                "min_latitude": 18.5204,
                "min_longitude": 73.8567,
                "max_latitude": 18.5210,
                "max_longitude": 73.8575,
            },
        }

        prop = PropertyParser.parse_raw_property(raw_data)

        # -------------------------------------------------
        # Property
        # -------------------------------------------------

        self.assertEqual(
            prop.property_id,
            "PROP-999",
        )

        self.assertEqual(
            prop.survey_number,
            "142",
        )

        self.assertEqual(
            prop.area_sq_meters,
            5000.0,
        )

        self.assertEqual(
            prop.plot_id,
            "PLOT-142",
        )

        self.assertEqual(
            prop.gis_code,
            "MH-2701-270101-52001",
        )

        # -------------------------------------------------
        # Owners
        # -------------------------------------------------

        self.assertEqual(
            len(prop.owners),
            2,
        )

        # First owner
        self.assertEqual(
            prop.owners[0].owner_name,
            "Owner One",
        )

        self.assertEqual(
            prop.owners[0].khata_number,
            "KH-101",
        )

        self.assertEqual(
            prop.owners[0].total_area,
            0.9800,
        )

        self.assertEqual(
            prop.owners[0].pot_kharaba,
            0.0000,
        )

        # Second owner
        self.assertEqual(
            prop.owners[1].owner_name,
            "Owner Two",
        )

        self.assertEqual(
            prop.owners[1].khata_number,
            "KH-102",
        )

        self.assertEqual(
            prop.owners[1].total_area,
            0.5000,
        )

        self.assertEqual(
            prop.owners[1].pot_kharaba,
            0.0800,
        )

        # -------------------------------------------------
        # Polygon
        # -------------------------------------------------

        self.assertIsNotNone(
            prop.polygon
        )

        self.assertEqual(
            len(prop.polygon.points),
            2,
        )

        self.assertEqual(
            prop.polygon.area_sq_meters,
            5000.0,
        )

        # -------------------------------------------------
        # Extent
        # -------------------------------------------------

        self.assertIsNotNone(
            prop.extent
        )

        self.assertEqual(
            prop.extent.min_latitude,
            18.5204,
        )

        self.assertEqual(
            prop.extent.min_longitude,
            73.8567,
        )

        self.assertEqual(
            prop.extent.max_latitude,
            18.5210,
        )

        self.assertEqual(
            prop.extent.max_longitude,
            73.8575,
        )


if __name__ == "__main__":
    unittest.main()