from typing import List, Optional
from app.schemas.location import LocationSchema
from app.schemas.survey import SurveySchema, PolygonPointSchema
from app.schemas.owner import OwnerSchema
from app.schemas.property import PropertySchema
from app.schemas.user import UserSchema


class MockDataRepository:
    def __init__(self):
        self._location = LocationSchema(
            latitude=18.5204,
            longitude=73.8567,
            address="Shivajinagar, Pune, Maharashtra 411005",
            district="Pune",
            taluka="Haveli",
            village="Shivajinagar",
            state="Maharashtra",
            pincode="411005"
        )
        
        self._owners = [
            OwnerSchema(
                owner_id="OWN-8821",
                full_name="Rajesh Suresh Patil",
                ownership_percentage=60.0,
                khata_number="KH-4902",
                contact_phone="+91 98220 12345"
            ),
            OwnerSchema(
                owner_id="OWN-8822",
                full_name="Sanjay Suresh Patil",
                ownership_percentage=40.0,
                khata_number="KH-4902",
                contact_phone="+91 98220 54321"
            )
        ]
        
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
                    PolygonPointSchema(latitude=18.5204, longitude=73.8567),
                    PolygonPointSchema(latitude=18.5210, longitude=73.8575),
                    PolygonPointSchema(latitude=18.5201, longitude=73.8582),
                    PolygonPointSchema(latitude=18.5195, longitude=73.8570),
                ],
                is_favorite=True
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
                    pincode="411004"
                ),
                owners=[
                    OwnerSchema(
                        owner_id="OWN-9011",
                        full_name="Meena Ramesh Deshmukh",
                        ownership_percentage=100.0,
                        khata_number="KH-1102"
                    )
                ],
                polygon_coordinates=[
                    PolygonPointSchema(latitude=18.5240, longitude=73.8590),
                    PolygonPointSchema(latitude=18.5250, longitude=73.8600),
                    PolygonPointSchema(latitude=18.5235, longitude=73.8610),
                ],
                is_favorite=False
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
                    pincode="411057"
                ),
                owners=[
                    OwnerSchema(
                        owner_id="OWN-7711",
                        full_name="Anil Kumar Sharma",
                        ownership_percentage=100.0,
                        khata_number="KH-3390"
                    )
                ],
                polygon_coordinates=[],
                is_favorite=True
            )
        ]
        
        self._user = UserSchema(
            user_id="USR-9901",
            name="Vikramaditya Kulkarni",
            email="vikram.kulkarni@geoproperty.ai",
            avatar_url="https://images.unsplash.com/photo-1534528741775-53994a69daeb",
            role="Senior GIS Land Analyst",
            saved_property_ids=["SURV-101", "SURV-103"],
            preferred_map_type="hybrid",
            notifications_enabled=True
        )

    async def get_current_location(self) -> LocationSchema:
        return self._location

    async def get_surveys(self, query: Optional[str] = None) -> List[SurveySchema]:
        if not query:
            return self._surveys
        q = query.lower()
        return [
            s for s in self._surveys
            if q in s.survey_number.lower()
            or q in s.village.lower()
            or q in s.district.lower()
        ]

    async def get_property_detail(self, property_id: str) -> PropertySchema:
        survey = next((s for s in self._surveys if s.id == property_id), self._surveys[0])
        return PropertySchema(
            property_id=survey.id,
            title=f"Survey No. {survey.survey_number}/{survey.subdivision_number} - {survey.village}",
            survey_details=survey,
            owners=survey.owners,
            total_area_hectares=round(survey.area_sq_meters / 10000.0, 4),
            boundary_points=survey.polygon_coordinates,
            valuation_estimate_inr=round(survey.area_sq_meters * 1850.0, 2),
            status="Government Verified"
        )

    async def get_user_profile(self) -> UserSchema:
        return self._user


mock_repository = MockDataRepository()
