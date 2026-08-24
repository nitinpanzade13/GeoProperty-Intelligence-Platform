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

        self._timeout = httpx.Timeout(
            settings.HTTP_TIMEOUT_SECONDS
        )

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
                follow_redirects=False,
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

        # Temporary HTTP errors that are safe to retry
        retryable_status_codes = {
            429,  # Too Many Requests
            500,  # Internal Server Error
            502,  # Bad Gateway
            503,  # Service Unavailable
            504,  # Gateway Timeout
        }

        for attempt in range(1, retries + 1):

            try:
                logger.info(
                    f"HTTP {method} {url} - "
                    f"Attempt {attempt}/{retries}"
                )

                response = await client.request(
                    method=method,
                    url=url,
                    params=params,
                    data=data,
                    json=json,
                    headers=headers,
                )

                #--------------------------------------------------
                # Log the response details for debugging
                #--------------------------------------------------

                logger.info(
                    f"GIS RESPONSE: status={response.status_code} "
                    f"url={response.url} "
                    f"location={response.headers.get('location')} "
                    f"content_type={response.headers.get('content-type')}"
                )

                #--------------------------------------------------
                # Handle WAF 302 Redirect Challenge
                #--------------------------------------------------
                
                if response.status_code == 302 and "set-cookie" in response.headers:
                    location = response.headers.get("location", "")
                    if location and (location in url or url.endswith(location)):
                        logger.info(
                            "WAF challenge detected (302 with set-cookie). "
                            "Retrying immediately as POST."
                        )
                        response = await client.request(
                            method=method,
                            url=url,
                            params=params,
                            data=data,
                            json=json,
                            headers=headers,
                        )
                        logger.info(
                            f"WAF Retry RESPONSE: status={response.status_code} "
                            f"url={response.url} "
                            f"content_type={response.headers.get('content-type')}"
                        )

                # --------------------------------------------------
                # Handle non-JSON responses
                # --------------------------------------------------
                
                if "application/json" not in (response.headers.get("content-type") or ""):
                    # Log snippet of body to diagnose HTML/error pages
                    body_snippet = response.text[:500] if hasattr(response, "text") else ""
                    logger.warning(
                        f"Non-JSON response from GIS: {response.status_code} "
                        f"{response.headers.get('content-type')} - "
                        f"Body: {repr(body_snippet)}"
                    )

                # --------------------------------------------------
                # Handle temporary HTTP failures
                # --------------------------------------------------

                if response.status_code in retryable_status_codes:

                    if attempt < retries:

                        # Exponential backoff:
                        #
                        # Attempt 1 -> wait 1 second
                        # Attempt 2 -> wait 2 seconds
                        # Attempt 3 -> wait 4 seconds
                        #
                        # Maximum wait is capped at 10 seconds.
                        delay = min(
                            2 ** (attempt - 1),
                            10,
                        )

                        logger.warning(
                            f"HTTP {response.status_code} from "
                            f"external GIS service. "
                            f"Retrying in {delay}s "
                            f"(attempt {attempt}/{retries})"
                        )

                        await asyncio.sleep(delay)

                        continue

                    # Last attempt failed.
                    logger.error(
                        f"HTTP {response.status_code} from "
                        f"external GIS service after "
                        f"{retries} attempts: {url}"
                    )

                    # Return the response so the caller can
                    # decide how to handle the final HTTP error.
                    return response

                # --------------------------------------------------
                # Successful or non-retryable HTTP response
                # --------------------------------------------------

                return response

            except (
                httpx.TimeoutException,
                httpx.ConnectError,
                httpx.NetworkError,
            ) as exc:

                logger.warning(
                    f"HTTP request failed on attempt "
                    f"{attempt}/{retries}: {exc}"
                )

                last_exception = exc

                if attempt < retries:

                    delay = min(
                        2 ** (attempt - 1),
                        10,
                    )

                    logger.info(
                        f"Retrying network request in "
                        f"{delay}s..."
                    )

                    await asyncio.sleep(delay)

        raise ExternalServiceException(
            detail=(
                f"External GIS service unavailable after "
                f"{retries} retries: {last_exception}"
            )
        )


# Shared HTTP client instance
gis_http_client = GISHttpClient()