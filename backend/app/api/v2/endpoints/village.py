from fastapi import APIRouter, Depends, Query
from typing import List
from app.schemas.response_wrapper import APIResponse
from app.schemas.village import (
    DistrictSchema,
    TalukaSchema,
    VillageSchema,
    GISCodeRequest,
    GISCodeResponse,
)
from app.services.village_service import VillageService
from app.providers.deps import get_village_service

router = APIRouter()


@router.get("/village/districts", response_model=APIResponse[List[DistrictSchema]])
async def get_districts(
    service: VillageService = Depends(get_village_service),
):
    """Retrieve list of state administrative districts."""
    districts = await service.get_districts()
    return APIResponse.ok(data=districts, message="Districts fetched successfully")


@router.get("/village/talukas", response_model=APIResponse[List[TalukaSchema]])
async def get_talukas(
    district_code: str = Query("2701", description="State District Code"),
    service: VillageService = Depends(get_village_service),
):
    """Retrieve list of talukas within a specified district."""
    talukas = await service.get_talukas(district_code)
    return APIResponse.ok(data=talukas, message="Talukas fetched successfully")


@router.get("/village/list", response_model=APIResponse[List[VillageSchema]])
async def get_villages(
    district_code: str = Query("2701", description="State District Code"),
    taluka_code: str = Query("270101", description="State Taluka Code"),
    service: VillageService = Depends(get_village_service),
):
    """Retrieve list of villages within a specified district and taluka."""
    villages = await service.get_villages(district_code, taluka_code)
    return APIResponse.ok(data=villages, message="Villages fetched successfully")


@router.post("/village/giscode", response_model=APIResponse[GISCodeResponse])
async def resolve_village_gis_code(
    payload: GISCodeRequest,
    service: VillageService = Depends(get_village_service),
):
    """Resolve state district, taluka, and village codes into a unified GIS code."""
    res = await service.resolve_village_gis_code(
        district_code=payload.district_code,
        taluka_code=payload.taluka_code,
        village_code=payload.village_code,
    )
    return APIResponse.ok(data=res, message="GIS code resolved successfully")
