import re
from typing import List, Optional, Dict, Any
from app.providers.base_provider import LandRecordsProvider
from app.models.domain_models import (
    District,
    Taluka,
    Village,
    Survey,
    Property,
    Owner,
    Polygon,
    Point2D,
    PlotExtent,
)
from app.utils.httpx_client import GISHttpClient, gis_http_client
from app.utils.cache import MemoryCache, memory_cache
from app.utils.parsers import PropertyParser
from app.utils.geometry_parser import GeometryParser
from app.utils.owner_parser import OwnerParser
from app.core.config import settings
from app.core.logging import logger
from app.core.exceptions import NotFoundException, ValidationException, ExternalServiceException


class MaharashtraLandRecordsProvider(LandRecordsProvider):
    """
    Production implementation of LandRecordsProvider for Maharashtra BhuNaksha REST services.
    Consumes live REST endpoints at https://mahabhunakasha.mahabhumi.gov.in/rest.
    No fabricated plot IDs, synthetic fallback GIS codes, or mock data are used.
    """

    REST_BASE_URL = "https://mahabhunakasha.mahabhumi.gov.in/rest"

    def __init__(
        self,
        http_client: GISHttpClient = gis_http_client,
        cache: MemoryCache = memory_cache,
    ):
        self.http_client = http_client
        self.cache = cache
        self.base_url = getattr(settings, "MH_BHUNAKSHA_BASE_URL", self.REST_BASE_URL)

    async def get_districts(self) -> List[District]:
        cache_key = "mh_districts"
        cached = self.cache.get(cache_key)
        if cached:
            logger.info("Cache hit for mh_districts")
            return cached

        url = f"{self.REST_BASE_URL}/VillageMapService/ListsAfterLevelGeoref"
        data = {
            "state": "27",
            "level": "1",
            "codes": "R,",
            "hasmap": "true",
        }

        try:
            response = await self.http_client.request("POST", url, data=data)
            raw_json = response.json()
        except Exception as exc:
            logger.error(f"Failed to fetch live districts from BhuNaksha REST API: {exc}")
            raise ExternalServiceException(detail=f"Districts API request failed: {str(exc)}")

        # Flatten nested list response [[{"code":"26","value":"Ahmednagar"},...]]
        items = (
            raw_json[0]
            if isinstance(raw_json, list) and len(raw_json) > 0 and isinstance(raw_json[0], list)
            else (raw_json if isinstance(raw_json, list) else [])
        )

        districts = [
            District(
                district_code=str(d.get("code")),
                district_name=str(d.get("value")),
                state_code="27",
            )
            for d in items
            if isinstance(d, dict) and "code" in d and "value" in d
        ]

        if not districts:
            logger.warning("Live BhuNaksha API returned empty district list.")
            raise NotFoundException(detail="No districts found from Maharashtra BhuNaksha service.")

        self.cache.set(cache_key, districts, ttl_seconds=settings.CACHE_VILLAGE_TTL_SECONDS)
        return districts

    async def get_talukas(self, district_code: str) -> List[Taluka]:
        cache_key = f"mh_talukas_{district_code}"
        cached = self.cache.get(cache_key)
        if cached:
            logger.info(f"Cache hit for mh_talukas_{district_code}")
            return cached

        url = f"{self.REST_BASE_URL}/VillageMapService/ListsAfterLevelGeoref"
        data = {
            "state": "27",
            "level": "2",
            "codes": f"R,{district_code},",
            "hasmap": "true",
        }

        try:
            response = await self.http_client.request("POST", url, data=data)
            raw_json = response.json()
        except Exception as exc:
            logger.error(f"Failed to fetch live talukas for district {district_code}: {exc}")
            raise ExternalServiceException(detail=f"Talukas API request failed: {str(exc)}")

        items = (
            raw_json[0]
            if isinstance(raw_json, list) and len(raw_json) > 0 and isinstance(raw_json[0], list)
            else (raw_json if isinstance(raw_json, list) else [])
        )

        talukas = [
            Taluka(
                taluka_code=str(t.get("code")),
                taluka_name=str(t.get("value")),
                district_code=district_code,
            )
            for t in items
            if isinstance(t, dict) and "code" in t and "value" in t
        ]

        if not talukas:
            logger.warning(f"No talukas found for district code: {district_code}")
            raise NotFoundException(detail=f"No talukas found for district code {district_code}.")

        self.cache.set(cache_key, talukas, ttl_seconds=settings.CACHE_VILLAGE_TTL_SECONDS)
        return talukas

    async def get_villages(self, district_code: str, taluka_code: str) -> List[Village]:
        cache_key = f"mh_villages_{district_code}_{taluka_code}"
        cached = self.cache.get(cache_key)
        if cached:
            logger.info(f"Cache hit for mh_villages_{district_code}_{taluka_code}")
            return cached

        url = f"{self.REST_BASE_URL}/VillageMapService/ListsAfterLevelGeoref"
        data = {
            "state": "27",
            "level": "3",
            "codes": f"R,{district_code},{taluka_code},",
            "hasmap": "true",
        }

        try:
            response = await self.http_client.request("POST", url, data=data)
            raw_json = response.json()
        except Exception as exc:
            logger.error(f"Failed to fetch live villages for {district_code}/{taluka_code}: {exc}")
            raise ExternalServiceException(detail=f"Villages API request failed: {str(exc)}")

        items = (
            raw_json[0]
            if isinstance(raw_json, list) and len(raw_json) > 0 and isinstance(raw_json[0], list)
            else (raw_json if isinstance(raw_json, list) else [])
        )

        villages = []
        for v in items:
            if isinstance(v, dict) and "code" in v and "value" in v:
                v_code = str(v.get("code")).strip()
                v_name = str(v.get("value")).strip()
                gis_c = await self.get_village_gis_code(district_code, taluka_code, v_code)
                

                villages.append(
                    Village(
                        village_code=v_code,
                        village_name=v_name,
                        taluka_code=taluka_code,
                        gis_code=gis_c,
                    )
                )

        if not villages:
            logger.warning(f"No villages found for district: {district_code}, taluka: {taluka_code}")
            raise NotFoundException(detail=f"No villages found for taluka code {taluka_code}.")

        self.cache.set(cache_key, villages, ttl_seconds=settings.CACHE_VILLAGE_TTL_SECONDS)
        return villages

    async def get_village_gis_code(
        self, district_code: str, taluka_code: str, village_code: str
    ) -> str:
        """
        Constructs verified BhuNaksha GIS code using the strict 18-digit deterministic algorithm:
        district = village_code[2:4]
        taluka = village_code[6:8]
        gis_code = f"RVM{district}{taluka}{village_code}"

        Validates that village_code is exactly an 18-digit numeric string.
        Raises ValidationException if village_code does not conform.
        """
        clean_vcode = str(village_code).strip()
        if not re.match(r"^\d{18}$", clean_vcode):
            raise ValidationException(
                detail=f"Invalid village_code '{village_code}'. Must be an 18-digit numeric string conforming to BhuNaksha GIS specifications."
            )

        district_str = clean_vcode[2:4]
        taluka_str = clean_vcode[6:8]

        gis_code = f"RVM{district_str}{taluka_str}{clean_vcode}"
        logger.info(f"Constructed verified BhuNaksha GIS code: {gis_code}")
        return gis_code

    async def get_survey_numbers(self, gis_code: str) -> List[Survey]:
        cache_key = f"mh_surveys_{gis_code}"
        cached = self.cache.get(cache_key)
        if cached:
            logger.info(f"Cache hit for mh_surveys_{gis_code}")
            return cached

        url = f"{self.REST_BASE_URL}/VillageMapService/kidelistFromGisCodeMH"
        data = {
            "state": "27",
            "logedLevels": gis_code,
        }

        try:
            response = await self.http_client.request("POST", url, data=data)
            raw_json = response.json()
        except Exception as exc:
            logger.error(f"Failed to fetch live survey list for GIS code {gis_code}: {exc}")
            raise ExternalServiceException(detail=f"Survey numbers API request failed: {str(exc)}")

        survey_numbers_raw = []
        if isinstance(raw_json, list):
            for item in raw_json:
                if isinstance(item, str):
                    survey_numbers_raw.append(item)
                elif isinstance(item, dict):
                    val = item.get("survey_no") or item.get("plotno") or item.get("value") or item.get("code")
                    if val:
                        survey_numbers_raw.append(str(val))

        # Deduplicate while constructing Survey models
        seen = set()
        deduped: List[Survey] = []
        for s_num in survey_numbers_raw:
            clean_num = str(s_num).strip()
            if clean_num and clean_num not in seen:
                seen.add(clean_num)
                deduped.append(
                    Survey(
                        survey_id=f"{gis_code}-S{clean_num}",
                        survey_number=clean_num,
                        subdivision_number=None,
                        village_code=gis_code,
                        area_sq_meters=0.0,
                    )
                )

        if not deduped:
            logger.warning(f"No survey numbers returned for GIS code: {gis_code}")

        # Numerical sorting by survey number
        def _sort_key(srv: Survey) -> int:
            match = re.search(r"\d+", srv.survey_number)
            return int(match.group()) if match else 0

        deduped.sort(key=_sort_key)
        self.cache.set(cache_key, deduped, ttl_seconds=settings.CACHE_SURVEY_TTL_SECONDS)
        return deduped

    async def get_plot_details(self, gis_code: str, survey_number: str) -> Property:
        cache_key = f"mh_plot_detail_{gis_code}_{survey_number}"

        cached = self.cache.get(cache_key)
        if cached:
            logger.info(f"Cache hit for mh_plot_detail_{gis_code}_{survey_number}")
            return cached

        url = f"{self.REST_BASE_URL}/MapInfo/getPlotInfo"

        data = {
            "state": "27",
            "giscode": gis_code,
            "plotno": survey_number,
            "srs": "4326",
        }

        try:
            response = await self.http_client.request(
                "POST",
                url,
                data=data,
            )

            raw_json = response.json()

            

        except Exception as exc:
            logger.error(
                f"Failed to fetch live plot info for {gis_code}/{survey_number}: {exc}"
            )
            raise ExternalServiceException(
                detail=f"Plot info API request failed: {str(exc)}"
            )

        if not isinstance(raw_json, dict):
            raise NotFoundException(
                detail=f"Plot info for survey number {survey_number} not found."
            )

        wkt_geom = (
            raw_json.get("the_geom")
            or raw_json.get("wkt")
            or raw_json.get("wkt_geometry")
        )

        plot_id_val = raw_json.get("plotid") or raw_json.get("plot_id")

        if not plot_id_val:
            raise ValidationException(
                detail=(
                    f"Official plotid missing in BhuNaksha response "
                    f"for survey number {survey_number} "
                    f"(giscode: {gis_code})."
                )
            )

        plot_id = str(plot_id_val)

        area_val = float(
            raw_json.get("area")
            or raw_json.get("area_sq_meters")
            or 0.0
        )

        # ==========================================================
        # OWNER PARSING
        # ==========================================================

        owners_raw = raw_json.get("owners")

        if owners_raw:
            logger.info("Parsing owners from JSON owners field.")
            owners_data = OwnerParser.parse_owners(owners_raw)
        else:
            logger.info("Parsing owners from INFO string.")
        
            owners_data = OwnerParser.parse_owners(
                raw_json.get("info", "")
            )

        logger.info("=" * 80)
        logger.info("PARSED OWNERS")
        logger.info(owners_data)
        logger.info("=" * 80)

        raw_payload = {
            "property_id": f"PROP-{gis_code}-{survey_number}",
            "survey_number": str(raw_json.get("plotno") or survey_number),
            "area_sq_meters": area_val,
            "pot_kharaba_sq_meters": float(
                raw_json.get("pot_kharaba_sq_meters") or 0.0
            ),
            "plot_id": plot_id,
            "gis_code": gis_code,
            "wkt": wkt_geom,
            "owners": owners_data,
        }

        property_obj = PropertyParser.parse_raw_property(raw_payload)

        self.cache.set(
            cache_key,
            property_obj,
            ttl_seconds=settings.CACHE_DEFAULT_TTL_SECONDS,
        )

        return property_obj



    async def get_plot_extent(
        self, gis_code: str, survey_number: str
    ) -> PlotExtent:
        """
        Retrieves GIS extent bounds for a plot.
        Calls get_plot_details() to obtain official BhuNaksha `plotid`.
        Passes `plotid` to /MapInfo/getExtentGeoref as required by the REST API.
        Never fabricates plot IDs or coordinate fallbacks.
        """
        property_obj = await self.get_plot_details(gis_code, survey_number)
        plot_id = property_obj.plot_id

        url = f"{self.REST_BASE_URL}/MapInfo/getExtentGeoref"
        data = {
            "state": "27",
            "giscode": gis_code,
            "plotid": plot_id,
            "srs": "4326",
        }

        try:
            response = await self.http_client.request("POST", url, data=data)
            raw_json = response.json()

            if isinstance(raw_json, dict):
                min_lat = float(raw_json.get("minlat") or raw_json.get("ymin") or raw_json.get("min_latitude") or 0.0)
                min_lng = float(raw_json.get("minlng") or raw_json.get("xmin") or raw_json.get("min_longitude") or 0.0)
                max_lat = float(raw_json.get("maxlat") or raw_json.get("ymax") or raw_json.get("max_latitude") or 0.0)
                max_lng = float(raw_json.get("maxlng") or raw_json.get("xmax") or raw_json.get("max_longitude") or 0.0)

                if min_lat != 0.0 or min_lng != 0.0:
                    return PlotExtent(
                        min_latitude=min_lat,
                        min_longitude=min_lng,
                        max_latitude=max_lat,
                        max_longitude=max_lng,
                    )
        except Exception as exc:
            logger.warning(f"Live getExtentGeoref request for plotid {plot_id} encountered error: {exc}")

        # Fallback to extent calculated directly from plot's WKT geometry
        if property_obj.extent:
            return property_obj.extent

        raise NotFoundException(detail=f"Could not retrieve GIS extent bounds for survey {survey_number} (plotid: {plot_id}).")
