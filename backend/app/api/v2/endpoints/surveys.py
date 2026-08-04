from fastapi import APIRouter, Depends, Query
from app.schemas.response_wrapper import APIResponse
from app.schemas.survey import VillageSurveysResponse
from app.services.survey_service import SurveyService
from app.providers.deps import get_survey_service
from app.core.defaults import LEGACY_GIS_CODE

router = APIRouter()


@router.get("/survey/list", response_model=APIResponse[VillageSurveysResponse])
async def list_surveys(
    gis_code: str = Query(LEGACY_GIS_CODE, description="Unified Village GIS Code"),
    service: SurveyService = Depends(get_survey_service),
):
    """Retrieve numerically sorted and deduplicated survey numbers for a village GIS code."""
    res = await service.get_village_surveys(gis_code=gis_code)
    return APIResponse.ok(data=res, message="Survey list retrieved successfully")


@router.get("/village/surveys", response_model=APIResponse[VillageSurveysResponse], include_in_schema=False)
async def get_village_surveys_alias(
    gis_code: str = Query(LEGACY_GIS_CODE, description="Unified Village GIS Code"),
    service: SurveyService = Depends(get_survey_service),
):
    """Alias for /api/survey/list for backward compatibility."""
    return await list_surveys(gis_code=gis_code, service=service)
