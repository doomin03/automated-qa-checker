@echo off
setlocal

echo [android] checking ADB

where adb >nul 2>nul
if errorlevel 1 (
  echo [error] adb not found. Install Android SDK platform-tools and add it to PATH.
  exit /b 1
)

adb version
adb devices

where emulator >nul 2>nul
if errorlevel 1 (
  echo [warn] emulator command not found. Install Android Studio or Android SDK emulator.
) else (
  emulator -list-avds
)

endlocal
