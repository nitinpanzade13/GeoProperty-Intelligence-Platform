import unittest

from app.utils.owner_parser import OwnerParser


class TestOwnerParser(unittest.TestCase):

    def test_parse_owners_multiple(self):
        raw_data = [
            {
                "owner_name": "Rajesh Suresh Patil",
                "khata_number": "KH-4902",
                "total_area": 0.9800,
                "pot_kharaba": 0.0000,
            },
            {
                "owner_name": "Sanjay Suresh Patil",
                "khata_number": "KH-4902",
                "total_area": 0.5000,
                "pot_kharaba": 0.0800,
            },
        ]

        owners = OwnerParser.parse_owners(raw_data)

        self.assertEqual(len(owners), 2)

        # First owner
        self.assertEqual(
            owners[0].owner_name,
            "Rajesh Suresh Patil",
        )

        self.assertEqual(
            owners[0].khata_number,
            "KH-4902",
        )

        self.assertEqual(
            owners[0].total_area,
            0.9800,
        )

        self.assertEqual(
            owners[0].pot_kharaba,
            0.0000,
        )

        # Second owner
        self.assertEqual(
            owners[1].owner_name,
            "Sanjay Suresh Patil",
        )

        self.assertEqual(
            owners[1].khata_number,
            "KH-4902",
        )

        self.assertEqual(
            owners[1].total_area,
            0.5000,
        )

        self.assertEqual(
            owners[1].pot_kharaba,
            0.0800,
        )

    def test_parse_owners_bhunaksha_info(self):
        raw_data = """
        Survey No. : 113
        Total Area : 0.9800
        Pot kharaba : 0.0000
        Owner Name : दर्शना दिपक निचळ, प्रणव दिपक निचळ, मयुरी दिपक निचळ
        Khata No. : 118
        ---------------------------------
        Survey No. : 113
        Total Area : 0.0000
        Pot kharaba : 0.0800
        Owner Name : पोपटखेड ल.पा.विभाग अकोला
        Khata No. : 424
        """

        owners = OwnerParser.parse_owners(raw_data)

        self.assertEqual(len(owners), 2)

        # First BhuNaksha record
        self.assertEqual(
            owners[0].owner_name,
            "दर्शना दिपक निचळ, प्रणव दिपक निचळ, मयुरी दिपक निचळ",
        )

        self.assertEqual(
            owners[0].khata_number,
            "118",
        )

        self.assertEqual(
            owners[0].total_area,
            0.9800,
        )

        self.assertEqual(
            owners[0].pot_kharaba,
            0.0000,
        )

        # Second BhuNaksha record
        self.assertEqual(
            owners[1].owner_name,
            "पोपटखेड ल.पा.विभाग अकोला",
        )

        self.assertEqual(
            owners[1].khata_number,
            "424",
        )

        self.assertEqual(
            owners[1].total_area,
            0.0000,
        )

        self.assertEqual(
            owners[1].pot_kharaba,
            0.0800,
        )

    def test_parse_owners_empty(self):
        owners = OwnerParser.parse_owners(None)

        self.assertEqual(
            owners,
            [],
        )


if __name__ == "__main__":
    unittest.main()