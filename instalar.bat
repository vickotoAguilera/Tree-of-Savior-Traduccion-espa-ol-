@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo === Instalador de Tree of Savior en espanol ===
echo Cierra el juego antes de continuar.
pause
where py >nul 2>&1 && (py -3 instalar.py) || (where python >nul 2>&1 && (python instalar.py) || (echo.& echo No encontre Python. Instalalo desde https://www.python.org/downloads/ marcando "Add Python to PATH" y vuelve a ejecutar este archivo.))
echo.
pause
