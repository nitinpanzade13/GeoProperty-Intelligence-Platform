from app.providers.base_provider import LandRecordsProvider
from app.providers.maharashtra_provider import MaharashtraLandRecordsProvider

# Remote repositories
from app.repositories.remote.village_repository import VillageRepository
from app.repositories.remote.survey_repository import SurveyRepository
from app.repositories.remote.property_repository import PropertyRepository
from app.repositories.remote.map_repository import MapRepository

# Business repositories
from app.repositories.village_map_repository import VillageMapRepository
from app.repositories.mock_repository import mock_repository

# Cache repositories
from app.repositories.cache.district_cache_repository import (
    DistrictCacheRepository,
)
from app.repositories.cache.taluka_cache_repository import (
    TalukaCacheRepository,
)
from app.repositories.cache.village_cache_repository import (
    VillageCacheRepository,
)
from app.repositories.cache.village_map_cache_repository import (
    VillageMapCacheRepository,
)
from app.repositories.cache.property_cache_repository import (
    PropertyCacheRepository,
)

# Services
from app.services.location_service import LocationService
from app.services.village_service import VillageService
from app.services.survey_service import SurveyService
from app.services.property_service import PropertyService
from app.services.map_service import MapService
from app.services.village_map_service import VillageMapService
from app.services.profile_service import ProfileService
from app.services.admin_sync_service import AdminSyncService

from app.repositories.property_identify_repository import (
    PropertyIdentifyRepository,
)

from app.services.property_identify_service import (
    PropertyIdentifyService,
)


# ---------------------------------------------------------------------
# Singleton Provider
# ---------------------------------------------------------------------

_provider_instance: LandRecordsProvider = MaharashtraLandRecordsProvider()


def get_land_records_provider() -> LandRecordsProvider:
    return _provider_instance


# ---------------------------------------------------------------------
# Remote Repositories
# ---------------------------------------------------------------------

def get_village_repository() -> VillageRepository:
    return VillageRepository(
        provider=_provider_instance
    )


def get_survey_repository() -> SurveyRepository:
    return SurveyRepository(
        provider=_provider_instance
    )


def get_property_repository() -> PropertyRepository:
    return PropertyRepository(
        provider=_provider_instance
    )


def get_map_repository() -> MapRepository:
    return MapRepository(
        provider=_provider_instance
    )


def get_village_map_repository() -> VillageMapRepository:
    return VillageMapRepository(
        survey_repository=get_survey_repository(),
        property_repository=get_property_repository(),
    )


# ---------------------------------------------------------------------
# Cache Repositories
# ---------------------------------------------------------------------

def get_district_cache_repository() -> DistrictCacheRepository:
    return DistrictCacheRepository()


def get_taluka_cache_repository() -> TalukaCacheRepository:
    return TalukaCacheRepository()


def get_village_cache_repository() -> VillageCacheRepository:
    return VillageCacheRepository()


def get_village_map_cache_repository() -> VillageMapCacheRepository:
    return VillageMapCacheRepository()


def get_property_cache_repository() -> PropertyCacheRepository:
    return PropertyCacheRepository()


# ---------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------

def get_location_service() -> LocationService:
    return LocationService()


def get_village_service() -> VillageService:
    return VillageService(
        repository=get_village_repository(),
        district_cache_repository=get_district_cache_repository(),
        taluka_cache_repository=get_taluka_cache_repository(),
        village_cache_repository=get_village_cache_repository(),
    )


def get_survey_service() -> SurveyService:
    return SurveyService(
        repository=get_survey_repository(),
    )


def get_property_service() -> PropertyService:
    return PropertyService(
        repository=get_property_repository(),
    )


def get_map_service() -> MapService:
    return MapService(
        repository=get_map_repository(),
    )


def get_village_map_service() -> VillageMapService:
    return VillageMapService(
        repository=get_village_map_repository(),
        cache_repository=get_village_map_cache_repository(),
        property_cache_repository=get_property_cache_repository(),
    )


def get_profile_service() -> ProfileService:
    return ProfileService(
        repository=mock_repository,
    )


def get_property_identify_service() -> PropertyIdentifyService:
    return PropertyIdentifyService(
        repository=PropertyIdentifyRepository(
            cache_repository=get_village_map_cache_repository(),
        ),
    )


# ---------------------------------------------------------------------
# Admin Sync Service
# ---------------------------------------------------------------------

def get_admin_sync_service() -> AdminSyncService:
    return AdminSyncService(
        village_service=get_village_service(),
        village_map_service=get_village_map_service(),
        village_map_cache_repository=get_village_map_cache_repository(),
    )