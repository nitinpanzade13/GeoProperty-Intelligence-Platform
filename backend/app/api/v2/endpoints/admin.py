from fastapi import APIRouter, Depends, Query

from app.schemas.response_wrapper import APIResponse
from app.services.admin_sync_service import AdminSyncService
from app.providers.deps import get_admin_sync_service


router = APIRouter()


@router.post("/admin/sync/district")
async def sync_district(
    district_code: str = Query(
        ...,
        description="District code to synchronize",
    ),
    service: AdminSyncService = Depends(
        get_admin_sync_service
    ),
):
    """
    Fetch and save complete district data from
    Maharashtra BhuNaksha.

    Flow:
        District
        → Talukas
        → Villages
        → Properties
        → Owners
        → Village Map Cache
    """

    result = await service.sync_district(
        district_code=district_code
    )

    return APIResponse.ok(
        data=result,
        message="District synchronization completed",
    )