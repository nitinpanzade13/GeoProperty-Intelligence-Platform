from app.schemas.location import LocationResponse


class LocationService:
    async def get_current_location(
        self, latitude: float = 18.5204, longitude: float = 73.8567
    ) -> LocationResponse:
        return LocationResponse(
            latitude=latitude,
            longitude=longitude,
            address="Shivajinagar, Pune, Maharashtra 411005",
            district="Pune",
            taluka="Haveli",
            village="Shivajinagar",
            state="Maharashtra",
            pincode="411005",
        )
