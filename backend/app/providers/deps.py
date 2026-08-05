from app.providers.base_provider import LandRecordsProvider
from app.providers.maharashtra_provider import MaharashtraLandRecordsProvider

from app.repositories.remote.village_repository import VillageRepository
from app.repositories.remote.survey_repository import SurveyRepository
from app.repositories.remote.property_repository import PropertyRepository
from app.repositories.map_repository import MapRepository
from app.repositories.village_map_repository import VillageMapRepository
from app.repositories.mock_repository import mock_repository

from app.services.location_service import LocationService
from app.services.village_service import VillageService
from app.services.survey_service import SurveyService
from app.services.property_service import PropertyService
from app.services.map_service import MapService
from app.services.village_map_service import VillageMapService
from app.services.profile_service import ProfileService
from app.repositories.village_cache_repository import VillageCacheRepository

# Singleton provider instance
_provider_instance: LandRecordsProvider = MaharashtraLandRecordsProvider()


def get_land_records_provider() -> LandRecordsProvider:
    return _provider_instance


def get_village_repository() -> VillageRepository:
    return VillageRepository(provider=_provider_instance)


def get_survey_repository() -> SurveyRepository:
    return SurveyRepository(provider=_provider_instance)


def get_property_repository() -> PropertyRepository:
    return PropertyRepository(provider=_provider_instance)


def get_map_repository() -> MapRepository:
    return MapRepository(provider=_provider_instance)

def get_village_map_repository() -> VillageMapRepository:
    return VillageMapRepository(
        survey_repository=get_survey_repository(),
        property_repository=get_property_repository(),
    )

def get_village_cache_repository():
    return VillageCacheRepository()

def get_location_service() -> LocationService:
    return LocationService()


def get_village_service() -> VillageService:
    return VillageService(repository=get_village_repository())


def get_survey_service() -> SurveyService:
    return SurveyService(repository=get_survey_repository())


def get_property_service() -> PropertyService:
    return PropertyService(repository=get_property_repository())


def get_map_service() -> MapService:
    return MapService(repository=get_map_repository())

def get_village_map_service() -> VillageMapService:
    return VillageMapService(
        repository=get_village_map_repository(),
        cache_repository=get_village_cache_repository(),
    )

def get_profile_service() -> ProfileService:
    return ProfileService(repository=mock_repository)
