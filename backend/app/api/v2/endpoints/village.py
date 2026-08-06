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
from app.schemas.property_identify_response import (
    PropertyIdentifyResponse,
)

from app.services.village_service import VillageService
from app.services.village_map_service import VillageMapService
from app.services.property_identify_service import (
    PropertyIdentifyService,
)

from app.providers.deps import (
    get_village_service,
    get_village_map_service,
    get_property_identify_service,
)

router = APIRouter()


@router.get(
    "/village/districts",
    response_model=APIResponse[List[DistrictSchema]],
)
async def get_districts(
    service: VillageService = Depends(get_village_service),
):
    """Retrieve list of state administrative districts."""
    districts = await service.get_districts()

    return APIResponse.ok(
        data=districts,
        message="Districts fetched successfully",
    )


@router.get(
    "/village/talukas",
    response_model=APIResponse[List[TalukaSchema]],
)
async def get_talukas(
    district_code: str = Query(
        "2701",
        description="State District Code",
    ),
    service: VillageService = Depends(get_village_service),
):
    """Retrieve list of talukas."""
    talukas = await service.get_talukas(district_code)

    return APIResponse.ok(
        data=talukas,
        message="Talukas fetched successfully",
    )


@router.get(
    "/village/list",
    response_model=APIResponse[List[VillageSchema]],
)
async def get_villages(
    district_code: str = Query(
        "2701",
        description="State District Code",
    ),
    taluka_code: str = Query(
        "270101",
        description="State Taluka Code",
    ),
    service: VillageService = Depends(get_village_service),
):
    """Retrieve villages."""
    villages = await service.get_villages(
        district_code,
        taluka_code,
    )

    return APIResponse.ok(
        data=villages,
        message="Villages fetched successfully",
    )


@router.post(
    "/village/giscode",
    response_model=APIResponse[GISCodeResponse],
)
async def resolve_village_gis_code(
    payload: GISCodeRequest,
    service: VillageService = Depends(get_village_service),
):
    """Resolve GIS code."""

    result = await service.resolve_village_gis_code(
        district_code=payload.district_code,
        taluka_code=payload.taluka_code,
        village_code=payload.village_code,
    )

    return APIResponse.ok(
        data=result,
        message="GIS code resolved successfully",
    )


@router.get("/village/full-map")
async def get_complete_village_map(
    gis_code: str = Query(
        ...,
        description="Village GIS Code",
    ),
    service: VillageMapService = Depends(
        get_village_map_service,
    ),
):
    """
    Returns the complete village GeoJSON.
    """

    result = await service.get_complete_village_map(
        gis_code,
    )

    return APIResponse.ok(
        data=result,
        message="Village map generated successfully",
    )


@router.get(
    "/village/identify",
    response_model=APIResponse[PropertyIdentifyResponse],
)
async def identify_property(
    gis_code: str = Query(
        ...,
        description="Village GIS Code",
    ),
    latitude: float = Query(
        ...,
        description="Latitude",
    ),
    longitude: float = Query(
        ...,
        description="Longitude",
    ),
    service: PropertyIdentifyService = Depends(
        get_property_identify_service,
    ),
):
    """
    Identify the property containing
    the given coordinate.
    """

    result = service.identify_property(
        gis_code=gis_code,
        latitude=latitude,
        longitude=longitude,
    )

    if result is None:
        return APIResponse.fail(
            message="No property found at this location.",
        )

    return APIResponse.ok(
        data=result.model_dump(),
        message="Property identified successfully.",
    )