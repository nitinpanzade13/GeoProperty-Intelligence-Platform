from fastapi import APIRouter
from app.api.v2.endpoints import (
    location,
    village,
    surveys,
    property,
    health,
)

api_v2_router = APIRouter()

api_v2_router.include_router(health.router, tags=["Health Check"])
api_v2_router.include_router(location.router, tags=["Location Service"])
api_v2_router.include_router(village.router, tags=["Village & Hierarchy"])
api_v2_router.include_router(surveys.router, tags=["Survey Records"])
api_v2_router.include_router(property.router, tags=["Property & GIS Extent"])
