import unittest
from app.providers.deps import (
    get_village_service,
    get_survey_service,
    get_property_service,
    get_map_service,
)


class TestServices(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.village_service = get_village_service()
        self.survey_service = get_survey_service()
        self.property_service = get_property_service()
        self.map_service = get_map_service()

    async def test_village_service(self):
        res = await self.village_service.resolve_village_gis_code("2701", "270101", "52001")
        self.assertEqual(res.gis_code, "MH-2701-270101-52001")
        self.assertTrue(res.is_valid)

    async def test_survey_service(self):
        res = await self.survey_service.get_village_surveys("MH-2701-270101-52001")
        self.assertTrue(res.total_surveys > 0)

    async def test_property_service(self):
        res = await self.property_service.get_property_details(
            "MH-2701-270101-52001", "142"
        )
        self.assertEqual(res.survey_number, "142")
        self.assertTrue(len(res.owners) >= 1)

    async def test_map_service(self):
        res = await self.map_service.get_plot_extent("MH-2701-270101-52001", "142")
        self.assertEqual(res.plot_id, "PLOT-142")
        self.assertEqual(len(res.bounding_box), 4)


if __name__ == "__main__":
    unittest.main()
