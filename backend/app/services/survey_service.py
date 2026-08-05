from app.repositories.remote.survey_repository import SurveyRepository
from app.schemas.survey import VillageSurveysResponse, SurveySchema


class SurveyService:
    def __init__(self, repository: SurveyRepository):
        self.repository = repository

    async def get_village_surveys(self, gis_code: str) -> VillageSurveysResponse:
        surveys = await self.repository.fetch_surveys(gis_code)
        schemas = [
            SurveySchema(
                survey_id=s.survey_id,
                survey_number=s.survey_number,
                subdivision_number=s.subdivision_number,
                village_code=s.village_code,
                area_sq_meters=s.area_sq_meters,
            )
            for s in surveys
        ]
        return VillageSurveysResponse(
            village_code=gis_code.split("-")[-1] if "-" in gis_code else gis_code,
            gis_code=gis_code,
            total_surveys=len(schemas),
            surveys=schemas,
        )
