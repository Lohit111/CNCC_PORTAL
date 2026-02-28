"""Main API Router"""
from fastapi import APIRouter
from api.v1 import requests, roles, types, assignments, store_requests, users

api_router = APIRouter(prefix="/api/v1")

# Include v1 routers
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(requests.router, prefix="/requests", tags=["Requests"])
api_router.include_router(roles.router, prefix="/roles", tags=["Roles"])
api_router.include_router(types.router, prefix="/types", tags=["Types"])
api_router.include_router(assignments.router, prefix="/assignments", tags=["Assignments"])
api_router.include_router(store_requests.router, prefix="/store-requests", tags=["Store Requests"])
