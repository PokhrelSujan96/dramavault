from pathlib import Path
from typing import Any

import boto3

from app.core.config import settings


class R2Storage:
    def __init__(self) -> None:
        self.bucket = settings.cloudflare_r2_bucket
        self.client: Any = boto3.client(
            "s3",
            endpoint_url=(
                f"https://{settings.cloudflare_account_id}.r2.cloudflarestorage.com"
            ),
            aws_access_key_id=settings.cloudflare_r2_access_key_id,
            aws_secret_access_key=settings.cloudflare_r2_secret_access_key,
            region_name="auto",
        )

    def upload(self, path: Path, key: str, content_type: str) -> str:
        self.client.upload_file(
            str(path),
            self.bucket,
            key,
            ExtraArgs={"ContentType": content_type},
        )
        return self.signed_url(key)

    def exists(self, key: str) -> bool:
        try:
            self.client.head_object(Bucket=self.bucket, Key=key)
            return True
        except Exception as error:
            response = getattr(error, "response", {}) or {}
            code = response.get("Error", {}).get("Code")
            if code in {"404", "NoSuchKey", "NotFound"}:
                return False
            raise

    def upload_revision(
        self, path: Path, key: str, content_type: str, revision: str
    ) -> str:
        self.client.upload_file(
            str(path),
            self.bucket,
            key,
            ExtraArgs={
                "ContentType": content_type,
                "CacheControl": "public, max-age=300, must-revalidate",
                "Metadata": {"revision": revision},
            },
        )
        return self.signed_url(key)

    def public_url(self, key: str, revision: str | None = None) -> str:
        base = settings.cloudflare_r2_public_url.rstrip("/")
        if not base:
            return self.signed_url(key)
        url = f"{base}/{key.lstrip('/')}"
        return f"{url}?revision={revision}" if revision else url

    def published_url(self, key: str, revision: str | None = None) -> str:
        return self.public_url(key, revision)

    def mobile_url(self, key: str, revision: str | None = None) -> str:
        return self.public_url(key, revision)

    def signed_url(self, key: str) -> str:
        return str(
            self.client.generate_presigned_url(
                "get_object",
                Params={"Bucket": self.bucket, "Key": key},
                ExpiresIn=604800,
            )
        )

    def preview_url(self, key: str, revision: str | None = None) -> str:
        return str(
            self.client.generate_presigned_url(
                "get_object",
                Params={"Bucket": self.bucket, "Key": key},
                ExpiresIn=300,
            )
        )
