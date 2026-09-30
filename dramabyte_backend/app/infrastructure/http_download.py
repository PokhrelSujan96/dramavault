import time
from pathlib import Path
from typing import Any, cast

import httpx

MAX_ATTEMPTS = 4
RETRYABLE_STATUS = {408, 425, 429, 500, 502, 503, 504}


def get_json(
    url: str,
    params: dict[str, Any] | None = None,
    timeout: float = 20,
) -> dict[str, Any]:
    for attempt in range(MAX_ATTEMPTS):
        try:
            response = httpx.get(url, params=params, timeout=timeout)
            response.raise_for_status()
            return cast(dict[str, Any], response.json())
        except httpx.TransportError:
            if attempt + 1 == MAX_ATTEMPTS:
                raise
            time.sleep(_delay(attempt))
        except httpx.HTTPStatusError as error:
            retry = _retryable(error.response.status_code)
            if not retry or attempt + 1 == MAX_ATTEMPTS:
                raise
            time.sleep(_delay(attempt))
    raise RuntimeError("HTTP request retries exhausted")


def download_file(
    url: str,
    destination: Path,
    timeout: float = 300,
    max_bytes: int | None = None,
) -> None:
    for attempt in range(MAX_ATTEMPTS):
        try:
            with httpx.stream(
                "GET", url, timeout=timeout, follow_redirects=True
            ) as response:
                response.raise_for_status()
                length = int(response.headers.get("content-length", 0))
                if max_bytes is not None and length > max_bytes:
                    raise ValueError("Download exceeds the configured size limit")
                size = 0
                with destination.open("wb") as output:
                    for chunk in response.iter_bytes():
                        size += len(chunk)
                        if max_bytes is not None and size > max_bytes:
                            raise ValueError(
                                "Download exceeds the configured size limit"
                            )
                        output.write(chunk)
                if size == 0:
                    raise httpx.RemoteProtocolError("Download returned no data")
            return
        except httpx.TransportError:
            destination.unlink(missing_ok=True)
            if attempt + 1 == MAX_ATTEMPTS:
                raise
            time.sleep(_delay(attempt))
        except httpx.HTTPStatusError as error:
            destination.unlink(missing_ok=True)
            retry = _retryable(error.response.status_code)
            if not retry or attempt + 1 == MAX_ATTEMPTS:
                raise
            time.sleep(_delay(attempt))
    raise RuntimeError("Download retries exhausted")


def _retryable(status: int) -> bool:
    return status in RETRYABLE_STATUS


def _delay(attempt: int) -> float:
    return float(min(4, 0.5 * (2**attempt)))
