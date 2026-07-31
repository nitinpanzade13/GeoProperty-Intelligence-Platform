from fastapi import APIRouter, Depends
from app.schemas.location import LocationSchema
from app.services.location_service import LocationService
from app.providers.deps import get_location_service

router = APIRouter()


@router.get("/location", response_model=LocationSchema)
async def get_current_location(
    service: LocationService = Depends(get_location_service)
):
    """Retrieve current GPS location metadata and address details."""
    return await service.fetch_current_location()
