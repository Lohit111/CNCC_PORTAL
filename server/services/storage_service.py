"""Storage Service

Manages file uploads and downloads for request attachments using MinIO.

The service manages its own MinIO client (initialised once from env vars).

Public API:

    post_files(request_id, files)
        Upload files and persist their references to the DB.

    get_files(request_id)
        Return presigned download URLs for all files attached to a request.
"""

import io
import logging
import os
import uuid
from datetime import timedelta
from typing import List

from dotenv import load_dotenv
from fastapi import UploadFile
from minio import Minio
from minio.error import S3Error

from config.database import SessionLocal
from models.request_file import RequestFile


load_dotenv()

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# MinIO client — initialised once from environment
# ---------------------------------------------------------------------------

_ENDPOINT = (
    os.environ["STORAGE_ENDPOINT"]
    .removeprefix("http://")
    .removeprefix("https://")
)

_ACCESS_KEY = os.environ["STORAGE_ACCESS_KEY"]
_SECRET_KEY = os.environ["STORAGE_SECRET_KEY"]
_BUCKET = os.environ["STORAGE_BUCKET"]

_SECURE = os.getenv(
    "STORAGE_ENDPOINT",
    "",
).startswith("https://")


_client = Minio(
    endpoint=_ENDPOINT,
    access_key=_ACCESS_KEY,
    secret_key=_SECRET_KEY,
    secure=_SECURE,
)


# ---------------------------------------------------------------------------
# Ensure bucket exists at startup
# ---------------------------------------------------------------------------

try:
    if not _client.bucket_exists(_BUCKET):
        _client.make_bucket(_BUCKET)
        logger.info("Created MinIO bucket: %s", _BUCKET)
    else:
        logger.info("MinIO bucket ready: %s", _BUCKET)

except S3Error:
    logger.exception("Failed to initialise MinIO bucket")


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
    """Upload files to MinIO and persist their references to the database.

    Args:
        request_id: Parent request ID.
        files: FastAPI UploadFile objects from the multipart body.

    Returns:
        List of persisted RequestFile records.
    """

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

            # Upload the actual bytes to MinIO.
            _client.put_object(
                bucket_name=_BUCKET,
                object_name=key,
                data=io.BytesIO(content),
                length=file_size,
                content_type=content_type,
            )

            uploaded_keys.append(key)

            logger.info(
                "Uploaded file to MinIO: %s",
                key,
            )

            # Persist metadata and the MinIO object reference.
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

        # DB rollback does not undo MinIO uploads.
        # Remove any objects that were uploaded during this operation.
        for key in uploaded_keys:
            try:
                _client.remove_object(
                    bucket_name=_BUCKET,
                    object_name=key,
                )

                logger.info(
                    "Removed orphaned MinIO object: %s",
                    key,
                )

            except Exception:
                logger.exception(
                    "Failed to remove orphaned MinIO object: %s",
                    key,
                )

        raise

    finally:
        db.close()


def download_file(file_ref: str) -> tuple[bytes, str]:
    """Download a single file from MinIO and return its raw bytes + content-type.

    Args:
        file_ref: MinIO object key stored in the database.

    Returns:
        Tuple of (file_bytes, content_type).

    Raises:
        S3Error: if the object cannot be retrieved from MinIO.
    """

    response = _client.get_object(
        bucket_name=_BUCKET,
        object_name=file_ref,
    )

    try:
        data = response.read()
        content_type = response.headers.get(
            "Content-Type",
            "application/octet-stream",
        )
    finally:
        response.close()
        response.release_conn()

    return data, content_type


def get_files(request_id: str) -> List[dict]:
    """Return presigned download URLs for all files attached to a request.

    The generated URLs are valid for 1 hour.

    Args:
        request_id: Parent request ID.

    Returns:
        List of dictionaries containing file metadata and a presigned URL.
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
                url = _client.presigned_get_object(
                    bucket_name=_BUCKET,
                    object_name=record.file_ref,
                    expires=timedelta(hours=1),
                )

            except S3Error:
                logger.warning(
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