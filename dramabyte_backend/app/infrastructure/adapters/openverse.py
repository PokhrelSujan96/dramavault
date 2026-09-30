from pathlib import Path
from typing import Any
from uuid import UUID

from app.infrastructure.http_download import download_file, get_json


class OpenverseMusicProvider:
    base_url = "https://api.openverse.org/v1/audio/"
    licenses = {"cc0", "by"}
    categories = {"music", "sound_effect"}

    def search(
        self,
        query: str,
        page: int,
        page_size: int = 12,
        category: str = "music",
    ) -> dict[str, Any]:
        if category not in self.categories:
            raise ValueError("Unsupported Openverse audio category")
        data = get_json(
            self.base_url,
            params={
                "q": query,
                "license": "cc0,by",
                "mature": "false",
                "page": page,
                "page_size": page_size,
            },
            timeout=20,
        )
        tracks = []
        for item in data.get("results", []):
            item_category = item.get("category")
            if item_category and item_category != category:
                continue
            if str(item.get("license", "")).lower() not in self.licenses:
                continue
            try:
                tracks.append(self._track(item))
            except (ValueError, KeyError):
                continue
        return {
            "page": data.get("page", page),
            "page_count": data.get("page_count", 0),
            "result_count": data.get("result_count", 0),
            "results": tracks,
        }

    def get_track(
        self, track_id: str, category: str = "music"
    ) -> dict[str, Any]:
        if category not in self.categories:
            raise ValueError("Unsupported Openverse audio category")
        UUID(track_id)
        value = get_json(f"{self.base_url}{track_id}/", timeout=20)
        track = self._track(value)
        if track["license"] not in self.licenses or (
            track["category"] and track["category"] != category
        ):
            raise ValueError("This audio is not available for commercial projects")
        return track

    def download(
        self, track_id: str, destination: Path, category: str = "music"
    ) -> dict[str, Any]:
        track = self.get_track(track_id, category)
        download_file(
            track["audio_url"], destination, timeout=120, max_bytes=100_000_000
        )
        return track

    @staticmethod
    def _track(value: dict[str, Any]) -> dict[str, Any]:
        license_id = str(value.get("license", "")).lower()
        if license_id not in OpenverseMusicProvider.licenses:
            raise ValueError("Openverse returned a track with an unsupported license")
        audio_url = value.get("url")
        source_url = value.get("foreign_landing_url")
        if not isinstance(audio_url, str) or not audio_url.startswith("https://"):
            raise ValueError("Track has no secure preview URL")
        if not isinstance(source_url, str) or not source_url.startswith("https://"):
            raise ValueError("Track has no secure source page")
        version = str(value.get("license_version") or "4.0")[:25]
        license_url = value.get("license_url")
        if not isinstance(license_url, str) or not license_url.startswith("https://"):
            license_url = (
                "https://creativecommons.org/publicdomain/zero/1.0/"
                if license_id == "cc0"
                else f"https://creativecommons.org/licenses/by/{version}/"
            )
        attribution = value.get("attribution")
        if not isinstance(attribution, str) or not attribution:
            attribution = (
                f"{str(value.get('title') or 'Untitled track')[:200]} by "
                f"{str(value.get('creator') or 'Unknown creator')[:200]} "
                f"(CC {license_id.upper()} {version})"
            )
        return {
            "id": str(value["id"]),
            "title": str(value.get("title") or "Untitled track")[:200],
            "creator": str(value.get("creator") or "Unknown creator")[:200],
            "source_url": source_url,
            "audio_url": audio_url,
            "license": license_id,
            "license_version": version,
            "license_url": license_url[:500],
            "category": str(value.get("category") or ""),
            "duration": max(0, int(value.get("duration") or 0)) / 1000,
            "attribution": attribution[:2000],
        }
