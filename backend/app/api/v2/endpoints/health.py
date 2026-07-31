from fastapi import APIRouter
from app.schemas.response_wrapper import APIResponse
from app.core.config import settings

router = APIRouter()


@router.get("/health", response_model=APIResponse[dict])
async def health_check():
    """Health check endpoint confirming microservice status."""
    payload = {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "provider": settings.DEFAULT_STATE_PROVIDER,
    }
    return APIResponse.ok(data=payload, message="Backend service is operational")
