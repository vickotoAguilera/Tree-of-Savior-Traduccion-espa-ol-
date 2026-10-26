@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo === Desinstalar la traduccion al espanol ===
echo Cierra el juego antes de continuar.
pause
where py >nul 2>&1 && (py -3 instalar.py --desinstalar) || (where python >nul 2>&1 && (python instalar.py --desinstalar) || (echo No encontre Python.))
echo.
pause
