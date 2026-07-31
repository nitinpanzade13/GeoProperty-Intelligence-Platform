from pydantic import BaseModel, Field
from typing import Generic, TypeVar, Optional, Any
from datetime import datetime, timezone

T = TypeVar("T")


class APIResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str = "Operation completed successfully"
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    data: Optional[T] = None
    errors: Optional[Any] = None

    @classmethod
    def ok(cls, data: T, message: str = "Success") -> "APIResponse[T]":
        return cls(success=True, message=message, data=data, errors=None)

    @classmethod
    def fail(cls, message: str, errors: Optional[Any] = None) -> "APIResponse[T]":
        return cls(success=False, message=message, data=None, errors=errors)
