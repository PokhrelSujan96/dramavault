import os
from typing import Any

import fal_client

from app.core.config import settings


class FalMediaProvider:
    def __init__(self) -> None:
        os.environ["FAL_KEY"] = settings.fal_api_key

    def create_image(self, prompt: str, aspect_ratio: str) -> str:
        result: dict[str, Any] = fal_client.subscribe(
            "fal-ai/flux/schnell",
            arguments={
                "prompt": prompt,
                "image_size": self._image_size(aspect_ratio),
                "num_images": 1,
                "num_inference_steps": 4,
                "enable_safety_checker": True,
            },
        )
        return str(result["images"][0]["url"])

    def create_video(
        self,
        prompt: str,
        image_url: str,
        aspect_ratio: str,
    ) -> str:
        result: dict[str, Any] = fal_client.subscribe(
            "fal-ai/wan-i2v",
            arguments={
                "prompt": prompt,
                "image_url": image_url,
                "aspect_ratio": aspect_ratio,
                "resolution": "480p",
                "num_frames": 81,
                "enable_safety_checker": True,
            },
        )
        return str(result["video"]["url"])

    def _image_size(self, aspect_ratio: str) -> str:
        sizes = {
            "9:16": "portrait_16_9",
            "16:9": "landscape_16_9",
            "1:1": "square_hd",
        }
        return sizes[aspect_ratio]
