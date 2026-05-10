@echo off
setlocal
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"
where node >nul 2>nul
if %ERRORLEVEL%==0 (
  node x-post-server.js
) else (
  "C:\Users\myabe\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" x-post-server.js
)
pause
