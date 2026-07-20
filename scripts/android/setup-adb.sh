#!/usr/bin/env bash
set -euo pipefail

echo "[android] checking Android SDK and ADB"

if ! command -v adb >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install --cask android-platform-tools
  else
    echo "[error] adb not found. Install Android SDK platform-tools and add adb to PATH."
    exit 1
  fi
fi

adb version
adb devices

if command -v emulator >/dev/null 2>&1; then
  emulator -list-avds || true
else
  echo "[warn] emulator command not found. Install Android Studio or Android SDK emulator."
fi
