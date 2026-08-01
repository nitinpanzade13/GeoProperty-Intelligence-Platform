import unittest
from unittest.mock import AsyncMock, MagicMock
from app.providers.maharashtra_provider import MaharashtraLandRecordsProvider
from app.core.exceptions import ValidationException


class TestMaharashtraLandRecordsProvider(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.mock_http = MagicMock()
        self.provider = MaharashtraLandRecordsProvider(http_client=self.mock_http)

    async def test_get_village_gis_code_valid_18_digit(self):
        v_code = "270500010046290000"
        gis_code = await self.provider.get_village_gis_code("2705", "270501", v_code)
        self.assertEqual(gis_code, "RVM0501270500010046290000")

    async def test_get_village_gis_code_invalid_throws_exception(self):
        with self.assertRaises(ValidationException):
            await self.provider.get_village_gis_code("2701", "270101", "52001")

    async def test_get_districts(self):
        mock_response = MagicMock()
        mock_response.json.return_value = [[{"code": "2701", "value": "Pune"}]]
        self.mock_http.request = AsyncMock(return_value=mock_response)

        districts = await self.provider.get_districts()
        self.assertEqual(len(districts), 1)
        self.assertEqual(districts[0].district_code, "2701")
        self.assertEqual(districts[0].district_name, "Pune")

    async def test_get_plot_details_strict_plotid(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "plotno": "142",
            "plotid": "REAL_PLOT_142_XYZ",
            "area": 4500.0,
            "the_geom": "MULTIPOLYGON(((73.8567 18.5204, 73.8575 18.5210, 73.8567 18.5204)))",
            "info": "Owner Name : Rajesh Suresh Patil\nKhata No : KH-4902",
        }
        self.mock_http.request = AsyncMock(return_value=mock_response)

        prop = await self.provider.get_plot_details("RVM0501270500010046290000", "142")
        self.assertEqual(prop.plot_id, "REAL_PLOT_142_XYZ")
        self.assertEqual(len(prop.owners), 1)
        self.assertEqual(prop.owners[0].owner_name, "Rajesh Suresh Patil")
        self.assertEqual(prop.owners[0].khata_number, "KH-4902")

    async def test_get_plot_details_missing_plotid_throws_exception(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "plotno": "142",
            # plotid is missing!
        }
        self.mock_http.request = AsyncMock(return_value=mock_response)

        with self.assertRaises(ValidationException):
            await self.provider.get_plot_details("RVM0501270500010046290000", "142")


if __name__ == "__main__":
    unittest.main()
