@echo off
cd /d "%~dp0"
echo === Desinstalar la traduccion al espanol ===
echo Cierra el juego antes de continuar.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar.ps1" -Desinstalar
echo.
pause
