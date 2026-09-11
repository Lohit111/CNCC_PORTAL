"""Request File Controller"""

from typing import List

from fastapi import HTTPException, UploadFile
from fastapi.responses import Response
from sqlalchemy.orm import Session

from models.assignment import Assignment
from models.enums import UserRole
from models.request import Request
from models.request_file import RequestFile
from models.user import User
from services.storage_service import (
    download_file as storage_download_file,
    get_files as storage_get_files,
    post_files as storage_post_files,
)

def create_files(
    db: Session,
    request_id: str,
    user: User,
    files: List[UploadFile],
) -> dict:
    """Upload files to a request."""

    request = Request.get(
        db,
        {"id": request_id},
    )

    if not request:
        raise HTTPException(
            status_code=404,
            detail="Request not found",
        )

    if not files:
        raise HTTPException(
            status_code=400,
            detail="No files provided",
        )

    if not request.raised_by == user.id:
        raise HTTPException(
            status_code=403,
            detail="You are not authorized to upload files, Only the request creater can upload files to this request.",
        )

    records = storage_post_files(
        request_id=request_id,
        files=files,
    )

    return {
        "message": "Files uploaded successfully",
        "files": [
            {
                "id": record.id,
                "request_id": record.request_id,
                "file_name": record.file_name,
                "content_type": record.content_type,
                "file_size": record.file_size,
                "created_at": record.created_at.isoformat(),
            }
            for record in records
        ],
    }


def get_files(
    db: Session,
    request_id: str,
    user: User,
) -> dict:
    """Get files attached to a request."""

    request = Request.get(
        db,
        {"id": request_id},
    )

    if not request:
        raise HTTPException(
            status_code=404,
            detail="Request not found",
        )

    return {
        "files": storage_get_files(request_id),
    }


def download_file(
    db: Session,
    request_id: str,
    file_id: str,
    user: User,
) -> Response:
    """Stream a single file back to the client via the server.

    The server fetches the bytes from MinIO and returns them directly,
    so the client never needs a routable path to the storage backend.
    """

    request = Request.get(db, {"id": request_id})

    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    record = RequestFile.get_by_id(db, file_id=file_id, request_id=request_id)

    if not record:
        raise HTTPException(status_code=404, detail="File not found")

    data, content_type = storage_download_file(record.file_ref)

    return Response(
        content=data,
        media_type=content_type,
        headers={
            "Content-Disposition": f'attachment; filename="{record.file_name}"',
            "Content-Length": str(len(data)),
        },
    )