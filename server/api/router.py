"""Main API Router"""
from fastapi import APIRouter
from api.v1 import users, types, rooms
from api.v1.my_requests import index as my_requests
from api.v1.admin import index as admin
from api.v1.staff import index as staff
from api.v1.store import index as store

api_router = APIRouter(prefix="/api/v1")

# Include v1 routers
api_router.include_router(users.router)
api_router.include_router(rooms.router)
api_router.include_router(my_requests.router)
api_router.include_router(admin.router)
api_router.include_router(staff.router)
api_router.include_router(store.router)
api_router.include_router(types.router)
