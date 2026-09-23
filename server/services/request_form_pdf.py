"""Request Form PDF Service

Generates a filled PDF form from a template using request data.
"""

import io
import logging
from pathlib import Path
from typing import TYPE_CHECKING, Optional

from pypdf import PdfReader, PdfWriter
from pypdf.constants import FieldFlag

from models.request import Request

if TYPE_CHECKING:
    from models.user import UserTable

logger = logging.getLogger(__name__)

# Path to template PDF (should be in project root or server directory)
TEMPLATE_PATH = Path(__file__).parent.parent / "template.pdf"


def generate_request_form_pdf(
    request: Request,
    user_name: str,
    phone: str,
) -> bytes:
    """Generate a filled PDF form from template with request data.
    
    Args:
        request: Request model with data to fill into PDF
        user: UserTable model for raised_by person (optional for name, phone, etc.)
        
    Returns:
        PDF bytes ready to write/download
        
    Raises:
        FileNotFoundError: If template.pdf doesn't exist
        Exception: If PDF generation fails
    """
    
    if not TEMPLATE_PATH.exists():
        raise FileNotFoundError(f"Template PDF not found at {TEMPLATE_PATH}")
    
    try:
        department_field = f"{request.department}\n{request.room_no}"

        phone_field = f"Ext:\n Mob: {phone}" if phone else ""

        type_field = (
            f"Main Type: {request.main_type}\n"
            f"Sub Type: {request.sub_type}"
        )

        values = {
            "name": user_name,
            "department": department_field,
            "phone_number": phone_field,
            "description": request.description,
            "type": type_field,
        }
        
        logger.info(f"Generating PDF for request {request.id}")
        
        # Read template and create writer
        reader = PdfReader(TEMPLATE_PATH)
        writer = PdfWriter(clone_from=reader)
        
        # Fill form fields on all pages
        for page in writer.pages:
            writer.update_page_form_field_values(
                page,
                values,
                flags=FieldFlag.READ_ONLY,
                auto_regenerate=False,
            )
        
        # Write to bytes buffer
        buffer = io.BytesIO()
        writer.write(buffer)
        buffer.seek(0)
        
        logger.info(f"Successfully generated PDF for request {request.id}")
        return buffer.getvalue()
        
    except Exception as e:
        logger.exception(f"Failed to generate PDF for request {request.id}: {e}")
        raise
