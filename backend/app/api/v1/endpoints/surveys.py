from fastapi import APIRouter, Depends, Query
from typing import List, Optional
from app.schemas.survey import SurveySchema
from app.services.survey_service import SurveyService
from app.providers.deps import get_survey_service

router = APIRouter()


@router.get("/surveys", response_model=List[SurveySchema])
async def list_surveys(
    query: Optional[str] = Query(None, description="Search term for survey number or village"),
    service: SurveyService = Depends(get_survey_service)
):
    """Retrieve list of survey parcels with optional search filtering."""
    return await service.list_surveys(query=query)
