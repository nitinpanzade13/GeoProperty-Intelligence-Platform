from fastapi import APIRouter, Depends
from app.schemas.user import UserSchema
from app.services.profile_service import ProfileService
from app.providers.deps import get_profile_service

router = APIRouter()


@router.get("/profile", response_model=UserSchema)
async def get_user_profile(
    service: ProfileService = Depends(get_profile_service)
):
    """Retrieve active user profile information, settings, and saved properties."""
    return await service.get_user_profile()
