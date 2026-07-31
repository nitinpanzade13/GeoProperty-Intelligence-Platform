from pydantic import BaseModel, Field
from typing import Optional, List


class DistrictSchema(BaseModel):
    district_code: str
    district_name: str
    state_code: str = "27"


class TalukaSchema(BaseModel):
    taluka_code: str
    taluka_name: str
    district_code: str


class VillageSchema(BaseModel):
    village_code: str
    village_name: str
    taluka_code: str
    gis_code: Optional[str] = None


class GISCodeRequest(BaseModel):
    district_code: str = Field(..., description="State District Code")
    taluka_code: str = Field(..., description="State Taluka Code")
    village_code: str = Field(..., description="State Village Code")


class GISCodeResponse(BaseModel):
    village_code: str
    gis_code: str
    state: str = "Maharashtra"
    is_valid: bool = True
