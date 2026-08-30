from typing import List, Optional

from app.schemas.location import LocationSchema
from app.schemas.survey import SurveySchema, PolygonPointSchema
from app.schemas.owner import OwnerSchema
from app.schemas.property import PropertySchema
from app.schemas.user import UserSchema


class MockDataRepository:

    def __init__(self):

        # -------------------------------------------------
        # Location
        # -------------------------------------------------

        self._location = LocationSchema(
            latitude=18.5204,
            longitude=73.8567,
            address="Shivajinagar, Pune, Maharashtra 411005",
            district="Pune",
            taluka="Haveli",
            village="Shivajinagar",
            state="Maharashtra",
            pincode="411005",
        )

        # -------------------------------------------------
        # Owners
        # -------------------------------------------------

        self._owners = [
            OwnerSchema(
                owner_name="Rajesh Suresh Patil",
                khata_number="KH-4902",
                total_area=0.9800,
                pot_kharaba=0.0000,
            ),
            OwnerSchema(
                owner_name="Sanjay Suresh Patil",
                khata_number="KH-4902",
                total_area=0.5000,
                pot_kharaba=0.0800,
            ),
        ]

        # -------------------------------------------------
        # Surveys
        # -------------------------------------------------

        self._surveys = [

            SurveySchema(
                id="SURV-101",
                survey_number="142",
                subdivision_number="3/A",
                district="Pune",
                taluka="Haveli",
                village="Shivajinagar",
                area_sq_meters=4500.0,
                land_type="Agricultural / Irrigated",
                location=self._location,
                owners=self._owners,
                polygon_coordinates=[
                    PolygonPointSchema(
                        latitude=18.5204,
                        longitude=73.8567,
                    ),
                    PolygonPointSchema(
                        latitude=18.5210,
                        longitude=73.8575,
                    ),
                    PolygonPointSchema(
                        latitude=18.5201,
                        longitude=73.8582,
                    ),
                    PolygonPointSchema(
                        latitude=18.5195,
                        longitude=73.8570,
                    ),
                ],
                is_favorite=True,
            ),

            SurveySchema(
                id="SURV-102",
                survey_number="145",
                subdivision_number="1",
                district="Pune",
                taluka="Haveli",
                village="Shivajinagar",
                area_sq_meters=8200.5,
                land_type="Non-Agricultural (Commercial)",
                location=LocationSchema(
                    latitude=18.5240,
                    longitude=73.8590,
                    address="FC Road, Pune",
                    district="Pune",
                    taluka="Haveli",
                    village="Shivajinagar",
                    pincode="411004",
                ),
                owners=[
                    OwnerSchema(
                        owner_name="Meena Ramesh Deshmukh",
                        khata_number="KH-1102",
                        total_area=0.8200,
                        pot_kharaba=0.0000,
                    )
                ],
                polygon_coordinates=[
                    PolygonPointSchema(
                        latitude=18.5240,
                        longitude=73.8590,
                    ),
                    PolygonPointSchema(
                        latitude=18.5250,
                        longitude=73.8600,
                    ),
                    PolygonPointSchema(
                        latitude=18.5235,
                        longitude=73.8610,
                    ),
                ],
                is_favorite=False,
            ),

            SurveySchema(
                id="SURV-103",
                survey_number="88",
                subdivision_number="2/B",
                district="Pune",
                taluka="Mulshi",
                village="Hinjawadi",
                area_sq_meters=12400.0,
                land_type="Industrial / IT Zone",
                location=LocationSchema(
                    latitude=18.5912,
                    longitude=73.7389,
                    address="Phase 1, Hinjawadi, Pune",
                    district="Pune",
                    taluka="Mulshi",
                    village="Hinjawadi",
                    pincode="411057",
                ),
                owners=[
                    OwnerSchema(
                        owner_name="Anil Kumar Sharma",
                        khata_number="KH-3390",
                        total_area=1.2400,
                        pot_kharaba=0.0000,
                    )
                ],
                polygon_coordinates=[],
                is_favorite=True,
            ),
        ]

        # -------------------------------------------------
        # User
        # -------------------------------------------------

        self._user = UserSchema(
            user_id="USR-9901",
            name="Vikramaditya Kulkarni",
            email="vikram.kulkarni@geoproperty.ai",
            avatar_url=(
                "https://images.unsplash.com/"
                "photo-1534528741775-53994a69daeb"
            ),
            role="Senior GIS Land Analyst",
            saved_property_ids=[
                "SURV-101",
                "SURV-103",
            ],
            preferred_map_type="hybrid",
            notifications_enabled=True,
        )

    # -----------------------------------------------------
    # Location
    # -----------------------------------------------------

    async def get_current_location(self) -> LocationSchema:
        return self._location

    # -----------------------------------------------------
    # Surveys
    # -----------------------------------------------------

    async def get_surveys(
        self,
        query: Optional[str] = None,
    ) -> List[SurveySchema]:

        if not query:
            return self._surveys

        q = query.lower()

        return [
            survey
            for survey in self._surveys
            if (
                q in survey.survey_number.lower()
                or q in survey.village.lower()
                or q in survey.district.lower()
            )
        ]

    # -----------------------------------------------------
    # Property Details
    # -----------------------------------------------------

    async def get_property_detail(
        self,
        property_id: str,
    ) -> PropertySchema:

        survey = next(
            (
                survey
                for survey in self._surveys
                if survey.id == property_id
            ),
            self._surveys[0],
        )

        return PropertySchema(
            property_id=survey.id,
            title=(
                f"Survey No. "
                f"{survey.survey_number}/"
                f"{survey.subdivision_number} - "
                f"{survey.village}"
            ),
            survey_details=survey,
            owners=survey.owners,
            total_area_hectares=round(
                survey.area_sq_meters / 10000.0,
                4,
            ),
            boundary_points=survey.polygon_coordinates,
            valuation_estimate_inr=round(
                survey.area_sq_meters * 1850.0,
                2,
            ),
            status="Government Verified",
        )

    # -----------------------------------------------------
    # User Profile
    # -----------------------------------------------------

    async def get_user_profile(self) -> UserSchema:
        return self._user


mock_repository = MockDataRepository()