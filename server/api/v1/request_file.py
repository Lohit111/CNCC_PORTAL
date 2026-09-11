"""Request File API Endpoints"""

from typing import List

from fastapi import APIRouter, Depends, File, UploadFile
from fastapi.responses import Response
from sqlalchemy.orm import Session

from config.database import get_db
from controllers.request_file import create_files, download_file, get_files
from middleware.auth import get_current_user, require_role
from models.enums import UserRole
from models.user import User


router = APIRouter(
    prefix="/request-files",
    tags=["Request Files"],
    dependencies=[
        Depends(
            require_role(
                UserRole.USER,
                UserRole.ADMIN,
                UserRole.STAFF,
            )
        )
    ],
)


@router.post("/{request_id}")
async def create(
    request_id: str,
    files: List[UploadFile] = File(...),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload files to a request."""

    return create_files(
        db=db,
        request_id=request_id,
        user=user,
        files=files,
    )


@router.get("/{request_id}")
async def get(
    request_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get files attached to a request."""

    return get_files(
        db=db,
        request_id=request_id,
        user=user,
    )


@router.get("/{request_id}/{file_id}/download", response_class=Response)
async def download(
    request_id: str,
    file_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Download a single file's bytes, proxied through the server.

    The client receives raw bytes with the original Content-Type header,
    so no direct connection to the MinIO storage backend is needed.
    """

    return download_file(
        db=db,
        request_id=request_id,
        file_id=file_id,
        user=user,
    )