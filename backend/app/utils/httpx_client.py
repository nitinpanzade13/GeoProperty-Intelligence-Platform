import asyncio
from typing import Dict, Any, Optional

import httpx

from app.core.config import settings
from app.core.exceptions import ExternalServiceException
from app.core.logging import logger


class GISHttpClient:
    def __init__(self):
        self._limits = httpx.Limits(
            max_keepalive_connections=settings.HTTP_POOL_LIMITS_MAX_KEEPALIVE,
            max_connections=settings.HTTP_POOL_LIMITS_MAX_CONNECTIONS,
        )

        self._timeout = httpx.Timeout(settings.HTTP_TIMEOUT_SECONDS)

        self._headers = {
            "User-Agent": "GeoProperty-Intelligence-Platform/2.0",
            "Accept": "application/json, text/plain, */*",
        }

        self._client: Optional[httpx.AsyncClient] = None

    async def get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                limits=self._limits,
                timeout=self._timeout,
                headers=self._headers,
                follow_redirects=True,
            )
        return self._client

    async def close(self):
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def request(
        self,
        method: str,
        url: str,
        params: Optional[Dict[str, Any]] = None,
        data: Optional[Any] = None,
        json: Optional[Any] = None,
        headers: Optional[Dict[str, str]] = None,
    ) -> httpx.Response:

        client = await self.get_client()

        retries = settings.HTTP_MAX_RETRIES

        last_exception: Optional[Exception] = None

        for attempt in range(1, retries + 1):

            try:

                logger.info(
                    f"HTTP {method} {url} - Attempt {attempt}/{retries}"
                )

                response = await client.request(
                    method=method,
                    url=url,
                    params=params,
                    data=data,
                    json=json,
                    headers=headers,
                )

                # IMPORTANT:
                # Do NOT call response.raise_for_status().
                # The caller decides how to handle HTTP 4xx/5xx responses.
                return response

            except (
                httpx.TimeoutException,
                httpx.ConnectError,
                httpx.NetworkError,
            ) as exc:

                logger.warning(
                    f"HTTP request failed on attempt {attempt}: {exc}"
                )

                last_exception = exc

                if attempt < retries:
                    await asyncio.sleep(0.5 * attempt)

        raise ExternalServiceException(
            detail=(
                f"External GIS service unavailable after "
                f"{retries} retries: {last_exception}"
            )
        )


gis_http_client = GISHttpClient()