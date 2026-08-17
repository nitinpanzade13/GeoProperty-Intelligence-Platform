from pydantic import BaseModel, EmailStr


class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str


class AdminLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int

class AdminDashboardSummary(BaseModel):
    districts: int
    talukas: int
    villages: int
    properties: int
    owners: int
    village_maps: int

class AdminDashboardDistrict(BaseModel):
    district_code: str
    district_name: str
    taluka_count: int
    village_count: int
    map_count: int
    sync_status: str