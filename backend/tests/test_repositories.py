import unittest
from app.providers.maharashtra_provider import MaharashtraLandRecordsProvider
from backend.app.repositories.remote.village_repository import VillageRepository
from backend.app.repositories.remote.survey_repository import SurveyRepository
from app.repositories.property_repository import PropertyRepository


class TestRepositories(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.provider = MaharashtraLandRecordsProvider()
        self.village_repo = VillageRepository(self.provider)
        self.survey_repo = SurveyRepository(self.provider)
        self.property_repo = PropertyRepository(self.provider)

    async def test_village_repo(self):
        districts = await self.village_repo.fetch_districts()
        self.assertTrue(len(districts) > 0)

        gis_code = await self.village_repo.resolve_gis_code("2701", "270101", "52001")
        self.assertEqual(gis_code, "MH-2701-270101-52001")

    async def test_survey_repo(self):
        surveys = await self.survey_repo.fetch_surveys("MH-2701-270101-52001")
        self.assertTrue(len(surveys) > 0)

    async def test_property_repo(self):
        prop = await self.property_repo.fetch_property_details(
            "MH-2701-270101-52001", "142"
        )
        self.assertEqual(prop.survey_number, "142")


if __name__ == "__main__":
    unittest.main()
