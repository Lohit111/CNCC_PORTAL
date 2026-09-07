include .env

up:
	docker compose up -d

upsert-admin:
	docker compose exec api \
		uv run python upsert_admin.py

db-login:
	docker compose -f docker-compose.yml exec db \
		psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

down:
	docker compose down

rebuild:
	docker compose build
	docker compose up -d

dev-web:
	cd app && flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

dev-mobile:
	adb reverse tcp:8000 tcp:8000
	cd app && flutter run

dev-backend:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d db
	cd server && uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000

dev-upsert-admin:
	cd server && uv run python upsert_admin.py
