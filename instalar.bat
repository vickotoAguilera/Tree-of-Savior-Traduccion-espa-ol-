@echo off
cd /d "%~dp0"
echo === Instalador de Tree of Savior en espanol ===
echo Cierra el juego antes de continuar.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar.ps1"
echo.
pause
