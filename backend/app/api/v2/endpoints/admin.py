from fastapi import APIRouter, Depends, Query, HTTPException, status

from app.schemas.response_wrapper import APIResponse
from app.schemas.admin import (
    AdminLoginRequest,
    AdminLoginResponse,
    AdminDashboardSummary,
    AdminDashboardDistrict
)
from app.services.admin_sync_service import AdminSyncService
from app.providers.deps import get_admin_sync_service

from app.core.config import settings
from app.core.security import (
    verify_password,
    create_access_token,
)

from app.api.dependencies.admin_auth import get_current_admin


from app.services.admin_dashboard_service import (
    AdminDashboardService,
)

from app.providers.deps import (
    get_admin_sync_service,
    get_admin_dashboard_service,
)

from app.schemas.admin import (
    AdminLoginRequest,
    AdminLoginResponse,
    AdminDashboardSummary,
)

from app.services.village_map_service import VillageMapService
from app.repositories.cache.village_cache_repository import (
    VillageCacheRepository,
)
from app.providers.deps import (
    get_village_map_service,
    get_village_cache_repository,
)

router = APIRouter()


@router.post("/admin/auth/login")
async def admin_login(
    credentials: AdminLoginRequest,
):
    """
    Authenticate the administrator and return a JWT access token.
    """

    email = credentials.email.lower().strip()

    if email != settings.ADMIN_EMAIL.lower().strip():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not verify_password(
        credentials.password,
        settings.ADMIN_PASSWORD_HASH,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    access_token = create_access_token(
        data={
            "sub": email,
            "role": "admin",
        },
        secret_key=settings.JWT_SECRET_KEY,
        expires_minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES,
    )

    return APIResponse.ok(
        data=AdminLoginResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        ),
        message="Admin login successful",
    )


@router.get("/admin/dashboard/districts")
async def admin_dashboard_districts(
    service: AdminDashboardService = Depends(
        get_admin_dashboard_service
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Return district-level statistics for the admin dashboard.

    Requires authenticated admin access.
    """

    result = await service.get_district_overview()

    return APIResponse.ok(
        data=[
            AdminDashboardDistrict(**district)
            for district in result
        ],
        message="Admin district overview fetched successfully",
    )


@router.get("/admin/dashboard/summary")
async def admin_dashboard_summary(
    service: AdminDashboardService = Depends(
        get_admin_dashboard_service
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Return aggregate statistics for the admin dashboard.

    Requires authenticated admin access.
    """

    result = await service.get_summary()

    return APIResponse.ok(
        data=AdminDashboardSummary(**result),
        message="Admin dashboard summary fetched successfully",
    )

@router.post("/admin/sync/district")
async def sync_district(
    district_code: str = Query(
        ...,
        description="District code to synchronize",
    ),
    service: AdminSyncService = Depends(
        get_admin_sync_service
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Fetch and save complete district data from
    Maharashtra BhuNaksha.

    Requires authenticated admin access.

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

@router.post("/admin/sync/village-map")
async def sync_village_map(
    gis_code: str = Query(
        ...,
        description="GIS code of the village to synchronize",
    ),
    service: VillageMapService = Depends(
        get_village_map_service
    ),
    village_cache_repository: VillageCacheRepository = Depends(
        get_village_cache_repository
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Synchronize a single village map and its property data.

    Flow:
        Village
        → BhuNaksha
        → Properties
        → Owners
        → GeoJSON
        → Village Map Cache
    """

    gis_code = gis_code.strip()

    # ---------------------------------------------------------
    # 1. Verify village exists in PostgreSQL
    # ---------------------------------------------------------

    village = village_cache_repository.get_by_gis_code(
        gis_code
    )

    if not village:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Village not found for GIS code: {gis_code}",
        )

    # ---------------------------------------------------------
    # 2. Force synchronization
    # ---------------------------------------------------------

    geojson = await service.build_and_cache(
        gis_code
    )

    # ---------------------------------------------------------
    # 3. Return lightweight admin response
    # ---------------------------------------------------------

    return APIResponse.ok(
        data={
            "gis_code": gis_code,
            "village_name": village.village_name,
            "total_surveys": geojson.get(
                "total_surveys",
                0,
            ),
            "status": "synced",
        },
        message="Village map synchronization completed",
    )


@router.get(
    "/admin/dashboard/districts/{district_code}/talukas"
)
async def get_admin_taluka_overview(
    district_code: str,
    service: AdminDashboardService = Depends(
        get_admin_dashboard_service
    ),
    current_admin=Depends(get_current_admin),
):
    result = await service.get_taluka_overview(
        district_code
    )

    return APIResponse.ok(
        data=result,
        message="Admin taluka overview fetched successfully",
    )

@router.get(
    "/admin/dashboard/districts/{district_code}/talukas/{taluka_code}/villages"
)
async def get_admin_village_overview(
    district_code: str,
    taluka_code: str,
    service: AdminDashboardService = Depends(
        get_admin_dashboard_service
    ),
    current_admin=Depends(get_current_admin),
):
    result = await service.get_village_overview(
        district_code,
        taluka_code,
    )

    return APIResponse.ok(
        data=result,
        message="Admin village overview fetched successfully",
    )