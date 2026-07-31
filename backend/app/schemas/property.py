from pydantic import BaseModel, Field
from typing import List, Optional
from app.schemas.extent import Point2DSchema, PlotExtentSchema
from app.schemas.survey import SurveySchema
from app.schemas.owner import OwnerSchema


class OwnerSchema(BaseModel):
    owner_name: str
    khata_number: str
    area_share_sq_meters: float
    ownership_percentage: float = 100.0


class PolygonSchema(BaseModel):
    polygon_id: str
    points: List[Point2DSchema]
    area_sq_meters: float


class PropertyDetailsResponse(BaseModel):
    property_id: str
    survey_number: str
    area_sq_meters: float
    pot_kharaba_sq_meters: float
    plot_id: str
    gis_code: str
    owners: List[OwnerSchema]
    polygon: Optional[PolygonSchema] = None
    extent: Optional[PlotExtentSchema] = None


class PropertySchema(BaseModel):
    property_id: str = Field(..., description="Unique property reference ID")
    title: str = Field(..., description="Display title for property")
    survey_details: SurveySchema
    owners: List[OwnerSchema]
    total_area_hectares: float
    boundary_points: List[Point2DSchema] = []
    valuation_estimate_inr: Optional[float] = None
    status: str = "Verified"
