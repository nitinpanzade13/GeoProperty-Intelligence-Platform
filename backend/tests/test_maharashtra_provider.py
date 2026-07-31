import unittest
import asyncio
from app.providers.maharashtra_provider import MaharashtraLandRecordsProvider


class TestMaharashtraLandRecordsProvider(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.provider = MaharashtraLandRecordsProvider()

    async def test_get_districts(self):
        districts = await self.provider.get_districts()
        self.assertTrue(len(districts) > 0)
        self.assertEqual(districts[0].state_code, "27")

    async def test_get_village_gis_code(self):
        code = await self.provider.get_village_gis_code("2701", "270101", "52001")
        self.assertEqual(code, "MH-2701-270101-52001")

    async def test_get_survey_numbers_sorted_and_deduped(self):
        surveys = await self.provider.get_survey_numbers("MH-2701-270101-52001")
        self.assertTrue(len(surveys) > 0)
        # Verify deduplication (4 raw items -> 3 deduped items)
        self.assertEqual(len(surveys), 3)
        # Verify numerical sorting ("88", "142", "145")
        self.assertEqual(surveys[0].survey_number, "88")
        self.assertEqual(surveys[1].survey_number, "142")
        self.assertEqual(surveys[2].survey_number, "145")

    async def test_get_plot_details(self):
        prop = await self.provider.get_plot_details("MH-2701-270101-52001", "142")
        self.assertEqual(prop.survey_number, "142")
        self.assertTrue(len(prop.owners) >= 2)
        self.assertIsNotNone(prop.polygon)
        self.assertTrue(len(prop.polygon.points) > 0)

    async def test_get_plot_extent(self):
        extent = await self.provider.get_plot_extent("MH-2701-270101-52001", "142")
        self.assertIsNotNone(extent)
        self.assertTrue(extent.max_latitude >= extent.min_latitude)


if __name__ == "__main__":
    unittest.main()
