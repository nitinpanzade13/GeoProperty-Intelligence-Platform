from fastapi import APIRouter, Depends, Query
from app.schemas.response_wrapper import APIResponse
from app.schemas.property import PropertyDetailsResponse
from app.schemas.extent import PropertyExtentResponse
from app.services.property_service import PropertyService
from app.services.map_service import MapService
from app.providers.deps import get_property_service, get_map_service

router = APIRouter()


@router.get("/property/details", response_model=APIResponse[PropertyDetailsResponse])
async def get_property_details(
    gis_code: str = Query("MH-2701-270101-52001", description="Unified Village GIS Code"),
    survey_number: str = Query("142", description="Survey Number"),
    property_service: PropertyService = Depends(get_property_service),
):
    """Retrieve complete property, multi-owner breakdown, area metrics, and polygon boundaries."""
    res = await property_service.get_property_details(
        gis_code=gis_code, survey_number=survey_number
    )
    return APIResponse.ok(data=res, message="Property details fetched successfully")


@router.get("/property/extent", response_model=APIResponse[PropertyExtentResponse])
async def get_property_extent(
    gis_code: str = Query("MH-2701-270101-52001", description="Unified Village GIS Code"),
    survey_number: str = Query("142", description="Survey Number"),
    map_service: MapService = Depends(get_map_service),
):
    """Retrieve plot extent and bounding box coordinates for map centering."""
    res = await map_service.get_plot_extent(
        gis_code=gis_code, survey_number=survey_number
    )
    return APIResponse.ok(data=res, message="Property extent fetched successfully")
