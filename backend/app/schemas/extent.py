from pydantic import BaseModel, Field
from typing import List


class Point2DSchema(BaseModel):
    latitude: float
    longitude: float


class PlotExtentSchema(BaseModel):
    min_latitude: float
    min_longitude: float
    max_latitude: float
    max_longitude: float


class PropertyExtentResponse(BaseModel):
    plot_id: str
    extent: PlotExtentSchema
    bounding_box: List[Point2DSchema]
