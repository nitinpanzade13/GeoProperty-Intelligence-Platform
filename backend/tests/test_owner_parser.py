import unittest
from app.utils.owner_parser import OwnerParser


class TestOwnerParser(unittest.TestCase):
    def test_parse_owners_multiple(self):
        raw_data = [
            {
                "owner_name": "Rajesh Suresh Patil",
                "khata_number": "KH-4902",
                "area_share_sq_meters": 2700.0,
                "ownership_percentage": 60.0,
            },
            {
                "owner_name": "Sanjay Suresh Patil",
                "khata_number": "KH-4902",
                "area_share_sq_meters": 1800.0,
                "ownership_percentage": 40.0,
            },
        ]
        owners = OwnerParser.parse_owners(raw_data)

        self.assertEqual(len(owners), 2)
        self.assertEqual(owners[0].owner_name, "Rajesh Suresh Patil")
        self.assertEqual(owners[0].khata_number, "KH-4902")
        self.assertEqual(owners[0].area_share_sq_meters, 2700.0)
        self.assertEqual(owners[1].owner_name, "Sanjay Suresh Patil")
        self.assertEqual(owners[1].ownership_percentage, 40.0)

    def test_parse_owners_empty_fallback(self):
        owners = OwnerParser.parse_owners(None)
        self.assertEqual(len(owners), 1)
        self.assertEqual(owners[0].owner_name, "Default Registered Owner")


if __name__ == "__main__":
    unittest.main()
