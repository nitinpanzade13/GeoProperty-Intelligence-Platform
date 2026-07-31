from fastapi import APIRouter
from app.api.v1.endpoints import location, surveys, property, profile

api_router = APIRouter()

api_router.include_router(location.router, tags=["Location"])
api_router.include_router(surveys.router, tags=["Surveys"])
api_router.include_router(property.router, tags=["Property"])
api_router.include_router(profile.router, tags=["Profile"])
