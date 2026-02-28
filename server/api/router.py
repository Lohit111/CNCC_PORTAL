"""Main API Router"""
from fastapi import APIRouter
from api.v1 import requests, roles, types, assignments, store_requests

api_router = APIRouter(prefix="/api")

# Include v1 routers
api_router.include_router(requests.router, prefix="/v1/requests", tags=["Requests"])
api_router.include_router(roles.router, prefix="/v1/roles", tags=["Roles"])
api_router.include_router(types.router, prefix="/v1/types", tags=["Types"])
api_router.include_router(assignments.router, prefix="/v1/assignments", tags=["Assignments"])
api_router.include_router(store_requests.router, prefix="/v1/store-requests", tags=["Store Requests"])
