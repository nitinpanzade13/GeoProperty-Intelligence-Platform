import asyncio
from typing import Set


class RefreshManager:
    """
    Prevents multiple background refreshes
    for the same village from running simultaneously.
    """

    _refreshing: Set[str] = set()
    _lock = asyncio.Lock()

    @classmethod
    async def start_refresh(cls, gis_code: str) -> bool:
        """
        Returns True if caller can start refresh.
        Returns False if another refresh is already running.
        """
        async with cls._lock:

            if gis_code in cls._refreshing:
                return False

            cls._refreshing.add(gis_code)
            return True

    @classmethod
    async def finish_refresh(cls, gis_code: str):

        async with cls._lock:
            cls._refreshing.discard(gis_code)

    @classmethod
    async def is_refreshing(cls, gis_code: str) -> bool:

        async with cls._lock:
            return gis_code in cls._refreshing