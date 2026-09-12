"""Storage Service

Manages file uploads and downloads for request attachments using
an S3-compatible object storage service.

The service manages its own S3 client (initialised once from env vars).

Public API:

    post_files(request_id, files)
        Upload files and persist their references to the DB.

    get_files(request_id)
        Return presigned download URLs for all files attached to a request.

    download_file(file_ref)
        Download a single file.
"""

import logging
import os
import uuid
from typing import List

import boto3
from botocore.config import Config
from dotenv import load_dotenv
from fastapi import UploadFile

from config.database import SessionLocal
from models.request_file import RequestFile


load_dotenv()

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# S3 client — initialised once from environment
# ---------------------------------------------------------------------------

_ENDPOINT = os.environ["STORAGE_ENDPOINT"]
_ACCESS_KEY = os.environ["STORAGE_ACCESS_KEY"]
_SECRET_KEY = os.environ["STORAGE_SECRET_KEY"]
_BUCKET = os.environ["STORAGE_BUCKET"]
_REGION = os.getenv("STORAGE_REGION", "us-east-1")


_client = boto3.client(
    "s3",
    endpoint_url=_ENDPOINT,
    aws_access_key_id=_ACCESS_KEY,
    aws_secret_access_key=_SECRET_KEY,
    region_name=_REGION,
    config=Config(
        signature_version="s3v4",
        s3={
            "addressing_style": "path",
        },
    ),
)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _object_key(request_id: str, filename: str) -> str:
    """Build a unique object key for a file."""

    return f"requests/{request_id}/{uuid.uuid4()}_{filename}"


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def post_files(
    request_id: str,
    files: List[UploadFile],
) -> List[RequestFile]:
    """Upload files to S3-compatible storage and persist references."""

    db = SessionLocal()

    # Keep track of uploaded objects so they can be removed if
    # the database transaction fails.
    uploaded_keys: List[str] = []

    try:
        records: List[RequestFile] = []

        for file in files:
            filename = file.filename or "file"
            content_type = (
                file.content_type
                or "application/octet-stream"
            )

            content = file.file.read()
            file_size = len(content)

            key = _object_key(
                request_id,
                filename,
            )

            # Upload file.
            _client.put_object(
                Bucket=_BUCKET,
                Key=key,
                Body=content,
                ContentLength=file_size,
                ContentType=content_type,
            )

            uploaded_keys.append(key)

            logger.info(
                "Uploaded file to object storage: %s",
                key,
            )

            # Persist metadata.
            record = RequestFile.create(
                db,
                request_id=request_id,
                file_ref=key,
                file_name=filename,
                content_type=content_type,
                file_size=file_size,
            )

            records.append(record)

        db.commit()

        logger.info(
            "Persisted %d file record(s) for request %s",
            len(records),
            request_id,
        )

        return records

    except Exception:
        db.rollback()

        logger.exception(
            "post_files failed for request %s",
            request_id,
        )

        # DB rollback does not undo object-storage uploads.
        for key in uploaded_keys:
            try:
                _client.delete_object(
                    Bucket=_BUCKET,
                    Key=key,
                )

                logger.info(
                    "Removed orphaned object: %s",
                    key,
                )

            except Exception:
                logger.exception(
                    "Failed to remove orphaned object: %s",
                    key,
                )

        raise

    finally:
        db.close()


def download_file(file_ref: str) -> tuple[bytes, str]:
    """Download a single file and return raw bytes + content type."""

    response = _client.get_object(
        Bucket=_BUCKET,
        Key=file_ref,
    )

    try:
        data = response["Body"].read()

        content_type = response.get(
            "ContentType",
            "application/octet-stream",
        )

    finally:
        response["Body"].close()

    return data, content_type


def get_files(request_id: str) -> List[dict]:
    """Return presigned download URLs for files attached to a request.

    URLs are valid for 1 hour.
    """

    db = SessionLocal()

    try:
        records = RequestFile.find_by_request(
            db,
            request_id=request_id,
        )

        result = []

        for record in records:
            try:
                url = _client.generate_presigned_url(
                    "get_object",
                    Params={
                        "Bucket": _BUCKET,
                        "Key": record.file_ref,
                    },
                    ExpiresIn=3600,
                )

            except Exception:
                logger.exception(
                    "Could not generate presigned URL for %s",
                    record.file_ref,
                )

                url = None

            result.append({
                "id": record.id,
                "request_id": record.request_id,
                "file_name": record.file_name,
                "content_type": record.content_type,
                "file_size": record.file_size,
                "url": url,
                "created_at": record.created_at.isoformat(),
            })

        return result

    finally:
        db.close()