.PHONY: up down rebuild frontend backend dev-frontend dev-backend
include .env

up:
	docker compose up -d

down:
	docker compose down

rebuild:
	docker compose build
	docker compose up -d

frontend:
	docker compose up -d cncc-portal

backend:
	docker compose up -d api

db-login:
	docker compose -f docker-compose.yml exec db \
		psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

dev-web:
	cd app && flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

dev-mobile:
	adb reverse tcp:8000 tcp:8000
	powershell -NoProfile -Command "$$devices = flutter devices --machine | ConvertFrom-Json; $$device = $$devices | Where-Object { $$_.targetPlatform -like 'android-*' -and $$_.isSupported } | Select-Object -First 1; if (-not $$device) { Write-Host 'No Android device connected.'; exit 1 }; Write-Host \"Running on $$($$device.name) ($$($$device.id))\"; Set-Location app; flutter run -d \"$$($$device.id)\""

dev-backend:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d db
	cd server && set "DATABASE_URL=postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@localhost:5432/$(POSTGRES_DB)" && uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000
