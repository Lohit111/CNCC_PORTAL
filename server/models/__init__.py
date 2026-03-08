"""Models Package - Import all models to ensure SQLAlchemy discovers relationships"""
from models.base import Base
from models.user import User, UserTable
from models.role import Role, RoleTable
from models.request import Request, RequestTable
from models.request_type import MainType, MainTypeTable, SubType, SubTypeTable
from models.track import RequestTrack, RequestTrackTable
from models.assignment import Assignment, AssignmentTable
from models.store_request import StoreRequest, StoreRequestTable
from models.store_chat import StoreChat, StoreChatTable

__all__ = [
    "Base",
    "User",
    "UserTable",
    "Role",
    "RoleTable",
    "Request",
    "RequestTable",
    "MainType",
    "MainTypeTable",
    "SubType",
    "SubTypeTable",
    "RequestTrack",
    "RequestTrackTable",
    "Assignment",
    "AssignmentTable",
    "StoreRequest",
    "StoreRequestTable",
    "StoreChat",
    "StoreChatTable",
]
