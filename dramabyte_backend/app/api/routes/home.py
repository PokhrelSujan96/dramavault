from fastapi import APIRouter, Depends

from app.api.dependencies import home_service
from app.application.home import HomeService
from app.domain.home import HomeFeed

router = APIRouter()


@router.get("", response_model=HomeFeed)
async def home(
    service: HomeService = Depends(home_service),
) -> HomeFeed:
    return await service.feed()
