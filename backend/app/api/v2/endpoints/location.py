from fastapi import APIRouter, Depends, Query
from app.schemas.response_wrapper import APIResponse
from app.schemas.location import LocationResponse
from app.services.location_service import LocationService
from app.providers.deps import get_location_service

router = APIRouter()


@router.get("/location/current", response_model=APIResponse[LocationResponse])
async def get_current_location(
    lat: float = Query(18.5204, description="Latitude in decimal degrees"),
    lng: float = Query(73.8567, description="Longitude in decimal degrees"),
    service: LocationService = Depends(get_location_service),
):
    """Retrieve current GPS location metadata and state/district administrative details."""
    result = await service.get_current_location(latitude=lat, longitude=lng)
    return APIResponse.ok(data=result, message="Current location retrieved successfully")
