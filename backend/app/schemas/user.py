from pydantic import BaseModel, Field
from typing import Optional, List


class UserSchema(BaseModel):
    user_id: str = Field(..., description="Unique user ID")
    name: str = Field(..., description="Full user name")
    email: str = Field(..., description="Email address")
    avatar_url: Optional[str] = None
    role: str = "Land Surveyor / Analyst"
    saved_property_ids: List[str] = []
    preferred_map_type: str = "hybrid"
    notifications_enabled: bool = True
