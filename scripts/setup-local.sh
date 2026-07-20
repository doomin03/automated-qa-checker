#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[setup] local QA environment"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[warn] macOS is the primary runtime target. Android ADB checks may still work on this platform."
fi

if command -v brew >/dev/null 2>&1; then
  if ! command -v node >/dev/null 2>&1; then
    brew install node
  fi
else
  echo "[warn] Homebrew not found. Skipping automatic Node.js installation."
fi

if command -v corepack >/dev/null 2>&1; then
  corepack enable
  corepack prepare pnpm@latest --activate
else
  echo "[warn] corepack not found. Install Node.js 20+ and enable pnpm manually."
fi

"$ROOT_DIR/scripts/android/setup-adb.sh"

if [[ "$(uname -s)" == "Darwin" ]]; then
  "$ROOT_DIR/scripts/ios/setup-simulator.sh"
else
  echo "[setup] skipping iOS Simulator setup outside macOS"
fi

echo "[setup] done"
