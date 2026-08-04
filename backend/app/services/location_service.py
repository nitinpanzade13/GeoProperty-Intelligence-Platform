from app.schemas.location import LocationResponse
from app.core.defaults import (
    DEFAULT_LATITUDE,
    DEFAULT_LONGITUDE,
    DEFAULT_STATE,
    DEFAULT_DISTRICT,
    DEFAULT_TALUKA,
    DEFAULT_VILLAGE,
    DEFAULT_PINCODE,
    DEFAULT_ADDRESS,
)


class LocationService:
    async def get_current_location(
        self, latitude: float = DEFAULT_LATITUDE, longitude: float = DEFAULT_LONGITUDE
    ) -> LocationResponse:
        return LocationResponse(
            latitude=latitude,
            longitude=longitude,
            address=DEFAULT_ADDRESS,
            district=DEFAULT_DISTRICT,
            taluka=DEFAULT_TALUKA,
            village=DEFAULT_VILLAGE,
            state=DEFAULT_STATE,
            pincode=DEFAULT_PINCODE,
        )
