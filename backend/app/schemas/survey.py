from pydantic import BaseModel, Field
from typing import Optional, List
from app.schemas.location import LocationSchema
from app.schemas.owner import OwnerSchema


class PolygonPointSchema(BaseModel):
    latitude: float
    longitude: float


class SurveySchema(BaseModel):
    id: str = Field(default="", description="Unique survey ID")
    survey_id: Optional[str] = None
    survey_number: str = Field(..., description="Survey Number e.g. 142")
    subdivision_number: Optional[str] = Field(None, description="Hissa / Subdivision Number")
    district: Optional[str] = Field("Pune", description="District Name")
    taluka: Optional[str] = Field("Haveli", description="Taluka Name")
    village: Optional[str] = Field("Shivajinagar", description="Village Name")
    village_code: Optional[str] = None
    area_sq_meters: float = Field(..., description="Total land area in sq. meters")
    land_type: Optional[str] = Field("Agricultural", description="Land classification type")
    location: Optional[LocationSchema] = None
    owners: List[OwnerSchema] = []
    polygon_coordinates: List[PolygonPointSchema] = []
    is_favorite: bool = False


class VillageSurveysResponse(BaseModel):
    village_code: str
    gis_code: str
    total_surveys: int
    surveys: List[SurveySchema]
