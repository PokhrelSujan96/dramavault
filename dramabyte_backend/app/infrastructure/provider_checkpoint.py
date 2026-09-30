from collections.abc import Callable
from typing import Any

from fal_client.client import FalClientHTTPError


def submit_once(
    submit: Callable[[], Any],
    reject: Callable[[], None],
) -> Any:
    try:
        return submit()
    except FalClientHTTPError as error:
        if error.status_code in {400, 401, 402, 403, 404, 422}:
            reject()
        raise


def result_once(
    retrieve: Callable[[], Any],
    reject: Callable[[], None],
) -> Any:
    try:
        return retrieve()
    except FalClientHTTPError as error:
        if error.status_code in {400, 402, 403, 404, 422}:
            reject()
        raise
