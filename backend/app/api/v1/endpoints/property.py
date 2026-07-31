from fastapi import APIRouter, Depends, Query
from app.schemas.property import PropertySchema
from app.services.property_service import PropertyService
from app.providers.deps import get_property_service

router = APIRouter()


@router.get("/property", response_model=PropertySchema)
async def get_property_detail(
    property_id: str = Query("SURV-101", description="Property ID to query"),
    service: PropertyService = Depends(get_property_service)
):
    """Retrieve detailed property, owner, valuation, and polygon boundary data."""
    return await service.get_property_details(property_id=property_id)
