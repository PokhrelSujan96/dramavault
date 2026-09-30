from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.api.dependencies import library_service
from app.application.library import LibraryService
from app.core.security import Principal, current_principal
from app.domain.library import LibraryError, LibraryItem

router = APIRouter()

_FAILURES = {
    "series_not_found": (404, "This series is not available"),
    "library_full": (409, "Your library is full. Remove a series to add another"),
    "user_unavailable": (403, "Your account cannot save series"),
}


@router.get("", response_model=list[LibraryItem])
async def my_library(
    principal: Principal = Depends(current_principal),
    service: LibraryService = Depends(library_service),
) -> list[LibraryItem]:
    return await service.items(UUID(principal.user_id))


@router.put("/{series_id}", status_code=204)
async def save_series(
    series_id: UUID,
    principal: Principal = Depends(current_principal),
    service: LibraryService = Depends(library_service),
) -> None:
    try:
        await service.add(UUID(principal.user_id), series_id)
    except LibraryError as error:
        status, detail = _FAILURES.get(error.code, (400, "Could not save series"))
        raise HTTPException(status_code=status, detail=detail) from error


@router.delete("/{series_id}", status_code=204)
async def remove_series(
    series_id: UUID,
    principal: Principal = Depends(current_principal),
    service: LibraryService = Depends(library_service),
) -> None:
    await service.remove(UUID(principal.user_id), series_id)
