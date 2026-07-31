from typing import Any, Dict


def format_api_response(data: Any, message: str = "Success") -> Dict[str, Any]:
    return {
        "status": "success",
        "message": message,
        "data": data
    }
