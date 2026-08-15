from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class District:
    district_code: str
    district_name: str
    state_code: str = "27"  # Maharashtra state code by default


@dataclass
class Taluka:
    taluka_code: str
    taluka_name: str
    district_code: str


@dataclass
class Village:
    village_code: str
    village_name: str
    district_code: str
    taluka_code: str
    gis_code: Optional[str] = None


@dataclass
class Owner:
    owner_name: str
    khata_number: str
    area_share_sq_meters: float
    ownership_percentage: float = 100.0


@dataclass
class Point2D:
    latitude: float
    longitude: float


@dataclass
class Polygon:
    polygon_id: str
    points: List[Point2D] = field(default_factory=list)
    area_sq_meters: float = 0.0


@dataclass
class PlotExtent:
    min_latitude: float
    min_longitude: float
    max_latitude: float
    max_longitude: float


@dataclass
class Survey:
    survey_id: str
    survey_number: str
    subdivision_number: Optional[str]
    village_code: str
    area_sq_meters: float


@dataclass
class Property:
    property_id: str
    survey_number: str
    area_sq_meters: float
    pot_kharaba_sq_meters: float
    plot_id: str
    gis_code: str
    owners: List[Owner] = field(default_factory=list)
    polygon: Optional[Polygon] = None
    extent: Optional[PlotExtent] = None
