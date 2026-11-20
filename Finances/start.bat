@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if %errorlevel%==0 (
  start "" http://127.0.0.1:8765
  py -3 -m http.server 8765
  goto :eof
)
where python >nul 2>nul
if %errorlevel%==0 (
  start "" http://127.0.0.1:8765
  python -m http.server 8765
  goto :eof
)
echo Python was not found. Install Python 3 or open index.html in a browser that supports local IndexedDB.
pause
