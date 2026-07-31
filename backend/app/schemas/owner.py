from pydantic import BaseModel, Field
from typing import Optional


class OwnerSchema(BaseModel):
    owner_id: Optional[str] = Field(None, description="Unique owner ID")
    owner_name: Optional[str] = Field(None, description="Full legal name of property owner")
    full_name: Optional[str] = Field(None, description="Full legal name of property owner")
    ownership_percentage: float = Field(100.0, description="Percentage of property owned")
    khata_number: Optional[str] = Field(None, description="Khata register number")
    contact_phone: Optional[str] = Field(None, description="Contact phone number")
    area_share_sq_meters: Optional[float] = Field(0.0, description="Area share in sq. meters")

    def model_post_init(self, __context):
        if not self.owner_name and self.full_name:
            self.owner_name = self.full_name
        elif not self.full_name and self.owner_name:
            self.full_name = self.owner_name
