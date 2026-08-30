from pydantic import BaseModel, Field
from typing import Optional


class OwnerSchema(BaseModel):
    owner_name: Optional[str] = Field(
        None,
        description="Full legal name of property owner",
    )

    khata_number: Optional[str] = Field(
        None,
        description="Khata register number",
    )

    total_area: float = Field(
        0.0,
        description="Total area reported by BhuNaksha in H.R. format",
    )

    pot_kharaba: float = Field(
        0.0,
        description="Pot Kharaba reported by BhuNaksha in H.R. format",
    )