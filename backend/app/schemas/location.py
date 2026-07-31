from pydantic import BaseModel, Field
from typing import Optional


class LocationSchema(BaseModel):
    latitude: float = Field(..., description="Latitude in decimal degrees")
    longitude: float = Field(..., description="Longitude in decimal degrees")
    address: Optional[str] = Field(None, description="Full human-readable address")
    district: Optional[str] = Field(None, description="District name")
    taluka: Optional[str] = Field(None, description="Taluka / Tehsil name")
    village: Optional[str] = Field(None, description="Village / Town name")
    state: Optional[str] = Field("Maharashtra", description="State name")
    pincode: Optional[str] = Field(None, description="6-digit postal code")


class LocationRequest(BaseModel):
    latitude: float = Field(..., description="Latitude in decimal degrees")
    longitude: float = Field(..., description="Longitude in decimal degrees")


class LocationResponse(BaseModel):
    latitude: float
    longitude: float
    address: str
    district: str
    taluka: str
    village: str
    state: str = "Maharashtra"
    pincode: Optional[str] = None
