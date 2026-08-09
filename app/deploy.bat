@echo off
setlocal enabledelayedexpansion

set LOGFILE=cloudflared.log

del %LOGFILE% 2>nul

start "" /b cloudflared tunnel --url localhost:8000 --protocol http2 > %LOGFILE% 2>&1

echo Waiting for URL...

:loop
timeout /t 2 >nul

for /f "tokens=2 delims=|" %%a in ('findstr "trycloudflare.com" %LOGFILE%') do (
    set URL=%%a
)

if not defined URL goto loop

set URL=%URL: =%

echo FOUND:
echo %URL%

set BACKEND_URL=%URL%/api/v1

echo Building with:
echo %BACKEND_URL%

start "Flutter Build" /wait cmd /c "flutter build web --release --dart-define=BACKEND_URL=%BACKEND_URL%"

if errorlevel 1 (
    echo Flutter build failed.
    exit /b 1
)

echo Flutter build completed.

echo Deploying Firebase...

firebase deploy

if errorlevel 1 (
    echo Firebase deploy failed.
    exit /b 1
)

echo Deployment completed successfully.

pause