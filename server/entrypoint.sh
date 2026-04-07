#!/bin/sh
python3 update_roles.py
exec uvicorn main:app --host 0.0.0.0 --port 8000
