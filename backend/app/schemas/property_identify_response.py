from typing import Optional, Dict, Any

from pydantic import BaseModel


class PropertyIdentifyResponse(BaseModel):
    """
    Response returned after identifying a property
    from a latitude/longitude coordinate.
    """

    survey_number: Optional[str] = None
    property_id: Optional[str] = None
    plot_id: Optional[str] = None
    area_sq_meters: Optional[float] = None
    owner_name: Optional[str] = None
    khata_number: Optional[str] = None

    geometry: Optional[Dict[str, Any]] = None