"""
Centralized fallback/default values used across the backend application.
All hardcoded fallback values should reference this module instead of
being scattered across individual files.
"""

# GPS Fallback (Pune, Maharashtra)
DEFAULT_LATITUDE = 18.5204
DEFAULT_LONGITUDE = 73.8567

# Administrative Hierarchy
DEFAULT_STATE = "Maharashtra"
DEFAULT_STATE_CODE = "27"
DEFAULT_DISTRICT = "Pune"
DEFAULT_TALUKA = "Haveli"
DEFAULT_VILLAGE = "Shivajinagar"
DEFAULT_PINCODE = "411005"
DEFAULT_ADDRESS = "Shivajinagar, Pune, Maharashtra 411005"

# GIS
DEFAULT_GIS_CODE = "RVM0501270500010046290000"
LEGACY_GIS_CODE = "MH-2701-270101-52001"

# Survey
DEFAULT_SURVEY_NUMBER = "142"
DEFAULT_LAND_TYPE = "Agricultural"

# Property
DEFAULT_STATUS = "Verified"

# Owner
UNKNOWN_OWNER = "Unknown Owner"
DEFAULT_OWNERSHIP_PERCENT = 100.0

# User
DEFAULT_USER_ROLE = "Land Surveyor / Analyst"

# BhuNaksha URLs
BHUNAKSHA_REST_BASE = "https://mahabhunakasha.mahabhumi.gov.in/rest"
BHUNAKSHA_WMS_BASE = "https://mahabhunakasha.mahabhumi.gov.in/WMS"
