from fastapi import APIRouter, Depends, Query, HTTPException, status

from app.schemas.response_wrapper import APIResponse

from app.schemas.admin import (
    AdminLoginRequest,
    AdminLoginResponse,
    AdminDashboardSummary,
    AdminDashboardDistrict,
)

from app.services.admin_sync_service import AdminSyncService
from app.services.admin_dashboard_service import AdminDashboardService
from app.services.village_map_service import VillageMapService

from app.services.admin_sync_registry import (
    admin_sync_registry,
)

from app.providers.deps import (
    get_admin_sync_service,
    get_admin_dashboard_service,
    get_village_map_service,
    get_village_cache_repository,
)

from app.repositories.cache.village_cache_repository import (
    VillageCacheRepository,
)

from app.core.config import settings

from app.core.security import (
    verify_password,
    create_access_token,
)

from app.api.dependencies.admin_auth import get_current_admin


router = APIRouter()


# =========================================================
# ADMIN AUTHENTICATION
# =========================================================

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


# =========================================================
# DASHBOARD
# =========================================================

@router.get("/admin/dashboard/districts")
async def admin_dashboard_districts(
    service: AdminDashboardService = Depends(
        get_admin_dashboard_service
    ),
    current_admin=Depends(get_current_admin),
):
    result = await service.get_district_overview()

    data = []

    for district in result:
        district_data = dict(district)

        district_code = str(
            district_data.get(
                "district_code",
                "",
            )
        )

        sync_job = admin_sync_registry.get(
            district_code
        )

        if (
            sync_job
            and sync_job.get(
                "sync_in_progress"
            )
        ):
            district_data["sync_status"] = (
                "syncing"
            )

        data.append(
            AdminDashboardDistrict(
                **district_data
            )
        )

    return APIResponse.ok(
        data=data,
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
    """

    result = await service.get_summary()

    return APIResponse.ok(
        data=AdminDashboardSummary(**result),
        message="Admin dashboard summary fetched successfully",
    )


# =========================================================
# DISTRICT SYNC
# =========================================================

@router.post("/admin/sync/district")
async def sync_district(
    district_code: str = Query(
        ...,
        description="District code to synchronize",
    ),
    force_refresh: bool = Query(
        False,
        description=(
            "If false, resume/skip villages already synchronized. "
            "If true, refetch all villages."
        ),
    ),
    service: AdminSyncService = Depends(
        get_admin_sync_service
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Start district synchronization asynchronously.

    The HTTP request returns immediately.
    The actual BhuNaksha synchronization continues in
    a background asyncio task.

    Frontend must poll:
        GET /admin/sync/district/status
    """

    district_code = district_code.strip()

    if not district_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="District code is required.",
        )

    result = service.start_district_sync(
        district_code=district_code,
        force_refresh=force_refresh,
    )

    return APIResponse.ok(
        data=result,
        message=(
            "District synchronization is already running."
            if result.get("already_running")
            else "District synchronization started."
        ),
    )

@router.get("/admin/sync/district/status")
async def get_district_sync_status(
    district_code: str = Query(
        ...,
        description="District code",
    ),
    service: AdminSyncService = Depends(
        get_admin_sync_service
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Return live district synchronization status.
    """

    district_code = district_code.strip()

    if not district_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="District code is required.",
        )

    result = service.get_district_sync_status(
        district_code
    )

    return APIResponse.ok(
        data=result,
        message="District synchronization status fetched.",
    )

# =========================================================
# TALUKA SYNC
# =========================================================

@router.post("/admin/sync/taluka")
async def sync_taluka(
    district_code: str = Query(
        ...,
        description="District code",
    ),
    taluka_code: str = Query(
        ...,
        description="Taluka code",
    ),
    force_refresh: bool = Query(
        False,
        description=(
            "If false, resume/skip villages that are already synced. "
            "If true, refetch all villages from BhuNaksha."
        ),
    ),
    service: AdminSyncService = Depends(
        get_admin_sync_service
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Synchronize every village belonging to a taluka.

    force_refresh=False:
        Resume/continue synchronization.
        Already synchronized villages can be skipped.

    force_refresh=True:
        Force-refresh all villages in the taluka from BhuNaksha.

    Flow:

        District
            ↓
        Taluka
            ↓
        Villages
            ↓
        Properties
            ↓
        Owners
            ↓
        Village Map Cache
    """

    district_code = district_code.strip()
    taluka_code = taluka_code.strip()

    if not district_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="District code is required",
        )

    if not taluka_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Taluka code is required",
        )

    result = await service.sync_taluka(
        district_code=district_code,
        taluka_code=taluka_code,
        force_refresh=force_refresh,
    )

    # ---------------------------------------------------------
    # Sync already running
    # ---------------------------------------------------------

    if result.get("sync_in_progress"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=result.get(
                "message",
                "Taluka synchronization is already in progress.",
            ),
        )

    return APIResponse.ok(
        data=result,
        message=(
            "Taluka force refresh completed"
            if force_refresh
            else "Taluka synchronization completed"
        ),
    )


# =========================================================
# VILLAGE SYNC
# =========================================================

@router.post("/admin/sync/village")
async def sync_village(
    gis_code: str = Query(
        ...,
        description="GIS code of the village to synchronize",
    ),
    force_refresh: bool = Query(
        False,
        description=(
            "If false, synchronize only when needed. "
            "If true, always refetch the village from BhuNaksha."
        ),
    ),
    service: AdminSyncService = Depends(
        get_admin_sync_service
    ),
    village_cache_repository: VillageCacheRepository = Depends(
        get_village_cache_repository
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Synchronize one village.

    force_refresh=False:
        Normal synchronization mode.

    force_refresh=True:
        Force refetch the village from BhuNaksha
        even if it already exists in PostgreSQL.

    Flow:

        Village
            ↓
        BhuNaksha
            ↓
        Properties
            ↓
        Owners
            ↓
        GeoJSON
            ↓
        Village Map Cache
    """

    gis_code = gis_code.strip()

    if not gis_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="GIS code is required",
        )

    village = village_cache_repository.get_by_gis_code(
        gis_code
    )

    if not village:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Village not found for GIS code: {gis_code}"
            ),
        )

    result = await service.sync_village(
        gis_code=gis_code,
        force_refresh=force_refresh,
    )

    # ---------------------------------------------------------
    # Sync already running
    # ---------------------------------------------------------

    if result.get("sync_in_progress"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=result.get(
                "message",
                "Village synchronization is already in progress.",
            ),
        )

    # ---------------------------------------------------------
    # Normal synchronization failure
    # ---------------------------------------------------------

    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=result.get(
                "error",
                "Village synchronization failed",
            ),
        )

    return APIResponse.ok(
        data={
            **result,
            "village_name": village.village_name,
        },
        message=(
            "Village force refresh completed"
            if force_refresh
            else "Village synchronization completed"
        ),
    )


# =========================================================
# EXISTING VILLAGE-MAP SYNC
# =========================================================

@router.post("/admin/sync/village-map")
async def sync_village_map(
    gis_code: str = Query(
        ...,
        description="GIS code of the village to synchronize",
    ),
    force_refresh: bool = Query(
        False,
        description=(
            "If true, force-refresh the village map from BhuNaksha."
        ),
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
    Existing village-map synchronization endpoint.

    Kept for backward compatibility.

    The newer /admin/sync/village endpoint should be preferred
    by the Admin Portal.

    force_refresh is accepted for compatibility with the
    Admin Portal sync controls.
    """

    gis_code = gis_code.strip()

    if not gis_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="GIS code is required",
        )

    village = village_cache_repository.get_by_gis_code(
        gis_code
    )

    if not village:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Village not found for GIS code: {gis_code}"
            ),
        )

    # -----------------------------------------------------
    # This endpoint already directly calls build_and_cache().
    #
    # build_and_cache() always fetches from BhuNaksha.
    # Therefore this endpoint behaves as a force refresh.
    # -----------------------------------------------------

    geojson = await service.build_and_cache(
        gis_code
    )

    return APIResponse.ok(
        data={
            "gis_code": gis_code,
            "village_name": village.village_name,
            "total_surveys": geojson.get(
                "total_surveys",
                0,
            ),
            "status": "refreshed" if force_refresh else "synced",
        },
        message=(
            "Village map force refresh completed"
            if force_refresh
            else "Village map synchronization completed"
        ),
    )


# =========================================================
# TALUKA OVERVIEW
# =========================================================

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
    """
    Return taluka-level statistics for a district.
    """

    result = await service.get_taluka_overview(
        district_code
    )

    return APIResponse.ok(
        data=result,
        message="Admin taluka overview fetched successfully",
    )


# =========================================================
# VILLAGE OVERVIEW
# =========================================================

@router.get(
    "/admin/dashboard/"
    "districts/{district_code}/"
    "talukas/{taluka_code}/villages"
)
async def get_admin_village_overview(
    district_code: str,
    taluka_code: str,
    service: AdminDashboardService = Depends(
        get_admin_dashboard_service
    ),
    current_admin=Depends(get_current_admin),
):
    """
    Return village-level statistics for a taluka.
    """

    result = await service.get_village_overview(
        district_code,
        taluka_code,
    )

    return APIResponse.ok(
        data=result,
        message="Admin village overview fetched successfully",
    )