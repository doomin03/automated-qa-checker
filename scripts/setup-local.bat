@echo off
setlocal

echo [setup] local QA helper for Windows
echo [setup] Android ADB checks can run on Windows.
echo [setup] iOS Simulator setup is macOS-only and is intentionally skipped.

call "%~dp0android\setup-adb.bat"
if errorlevel 1 exit /b 1

where node >nul 2>nul
if errorlevel 1 (
  echo [warn] Node.js is not installed or not on PATH.
) else (
  node --version
)

where pnpm >nul 2>nul
if errorlevel 1 (
  echo [warn] pnpm is not installed or not on PATH. Run: corepack enable
) else (
  pnpm --version
)

echo [setup] done
endlocal
