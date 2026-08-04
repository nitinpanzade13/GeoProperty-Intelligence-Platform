from fastapi import APIRouter, Depends, Query
from app.schemas.response_wrapper import APIResponse
from app.schemas.location import LocationResponse
from app.services.location_service import LocationService
from app.providers.deps import get_location_service
from app.core.defaults import DEFAULT_LATITUDE, DEFAULT_LONGITUDE

router = APIRouter()


@router.get("/location/current", response_model=APIResponse[LocationResponse])
async def get_current_location(
    lat: float = Query(DEFAULT_LATITUDE, description="Latitude in decimal degrees"),
    lng: float = Query(DEFAULT_LONGITUDE, description="Longitude in decimal degrees"),
    service: LocationService = Depends(get_location_service),
):
    """Retrieve current GPS location metadata and state/district administrative details."""
    result = await service.get_current_location(latitude=lat, longitude=lng)
    return APIResponse.ok(data=result, message="Current location retrieved successfully")
