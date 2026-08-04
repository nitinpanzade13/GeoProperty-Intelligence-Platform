from fastapi import APIRouter, Depends, Query, Response
from app.schemas.response_wrapper import APIResponse
from app.schemas.property import PropertyDetailsResponse
from app.schemas.extent import PropertyExtentResponse
from app.services.property_service import PropertyService
from app.services.map_service import MapService
from app.providers.deps import get_property_service, get_map_service
from app.utils.httpx_client import GISHttpClient, gis_http_client
from app.utils.cache import MemoryCache, memory_cache
from app.core.logging import logger
from fastapi import HTTPException
from app.core.defaults import DEFAULT_GIS_CODE, DEFAULT_SURVEY_NUMBER, BHUNAKSHA_WMS_BASE

router = APIRouter()

WMS_OFFICIAL_URL = BHUNAKSHA_WMS_BASE


@router.get("/property/details", response_model=APIResponse[PropertyDetailsResponse])
async def get_property_details(
    gis_code: str = Query(DEFAULT_GIS_CODE, description="Unified Village GIS Code"),
    survey_number: str = Query(DEFAULT_SURVEY_NUMBER, description="Survey Number"),
    property_service: PropertyService = Depends(get_property_service),
):
    """Retrieve complete property, multi-owner breakdown, area metrics, and polygon boundaries."""
    res = await property_service.get_property_details(
        gis_code=gis_code, survey_number=survey_number
    )
    return APIResponse.ok(data=res, message="Property details fetched successfully")


@router.get("/property/extent", response_model=APIResponse[PropertyExtentResponse])
async def get_property_extent(
    gis_code: str = Query(DEFAULT_GIS_CODE, description="Unified Village GIS Code"),
    survey_number: str = Query(DEFAULT_SURVEY_NUMBER, description="Survey Number"),
    map_service: MapService = Depends(get_map_service),
):
    """Retrieve plot extent and bounding box coordinates for map centering."""
    res = await map_service.get_plot_extent(
        gis_code=gis_code, survey_number=survey_number
    )
    return APIResponse.ok(data=res, message="Property extent fetched successfully")




@router.get("/map/wms")
async def get_wms_tile_proxy(
    gis_code: str = Query(..., description="Village BhuNaksha GIS Code"),
    bbox: str = Query(..., description="Tile Bounding Box (minx,miny,maxx,maxy)"),
    width: int = Query(256, description="Tile Width in pixels"),
    height: int = Query(256, description="Tile Height in pixels"),
    crs: str = Query("EPSG:3857", description="Coordinate Reference System"),
    transparent: str = Query("true", description="Transparent background flag"),
    format: str = Query("image/png", description="Image format"),
    version: str = Query("1.3.0", description="WMS Version"),
    styles: str = Query("VILLAGE_MAP", description="WMS Styles"),
    service: str = Query("WMS", description="Service type"),
    request_type: str = Query("GetMap", alias="request", description="WMS Request type"),
    layers: str = Query("VILLAGE_MAP", description="WMS Layer name"),
):
    """
    Backend proxy for Maharashtra Bhunaksha WMS.
    """

    cache_key = f"wms_{gis_code}_{bbox}_{width}_{height}_{crs}"

    cached_tile = memory_cache.get(cache_key)
    if isinstance(cached_tile, bytes):
        logger.info("Returning cached WMS tile")
        return Response(content=cached_tile, media_type="image/png")

    srs_key = "SRS" if version == "1.1.1" else "CRS"

    wms_params = {
        "SERVICE": service,
        "REQUEST": request_type,
        "VERSION": version,
        "LAYERS": layers,
        "STYLES": styles,
        "FORMAT": format,
        "TRANSPARENT": transparent,
        srs_key: crs,
        "WIDTH": str(width),
        "HEIGHT": str(height),
        "BBOX": bbox,

        # Maharashtra specific
        "state": "27",
        "gis_code": gis_code,
        "FORMAT_OPTIONS": "dpi:113",
    }

    logger.info("=" * 80)
    logger.info("OFFICIAL BHUNAKSHA WMS REQUEST")
    logger.info(WMS_OFFICIAL_URL)
    logger.info(wms_params)
    logger.info("=" * 80)

    try:
        response = await gis_http_client.request(
            "GET",
            WMS_OFFICIAL_URL,
            params=wms_params,
            headers={
                "Accept": "image/png,*/*",
            },
        )

        logger.info("=" * 80)
        logger.info(f"Status      : {response.status_code}")
        logger.info(f"ContentType : {response.headers.get('content-type')}")
        logger.info(f"Length      : {len(response.content)}")
        logger.info(f"Response URL: {response.url}")

        if response.headers.get("content-type", "").startswith("text"):
            logger.info("TEXT RESPONSE:")
            logger.info(response.text)
        logger.info("=" * 80)

        content_type = response.headers.get("content-type", "")

        if response.status_code != 200:
            logger.error(response.text)
            raise HTTPException(
                status_code=502,
                detail=f"Bhunaksha returned HTTP {response.status_code}",
            )

        if "image/png" not in content_type.lower():
            logger.error(response.text)
            raise HTTPException(
                status_code=502,
                detail="Bhunaksha did not return a PNG image.",
            )

        tile = response.content

        memory_cache.set(
            cache_key,
            tile,
            ttl_seconds=3600,
        )

        return Response(
            content=tile,
            media_type="image/png",
        )

    except HTTPException:
        raise

    except Exception as exc:
        logger.exception(exc)
        raise HTTPException(
            status_code=502,
            detail=f"WMS proxy failed: {exc}",
        )