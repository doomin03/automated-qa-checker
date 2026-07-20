#!/usr/bin/env bash
set -euo pipefail

echo "[ios] checking Xcode and iOS Simulator"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[error] iOS Simulator setup requires macOS."
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "[error] Xcode command line tools are required."
  exit 1
fi

sudo xcodebuild -license accept || true
xcode-select -p
xcrun simctl list devices available

if ! command -v appium >/dev/null 2>&1; then
  npm install -g appium
fi

appium driver list --installed | grep -q xcuitest || appium driver install xcuitest

echo "[ios] available runtimes"
xcrun simctl list runtimes available
