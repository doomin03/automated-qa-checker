#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="${1:-iPhone 15}"

echo "[ios] checking simulator: ${DEVICE_NAME}"

UDID="$(xcrun simctl list devices available | awk -v name="$DEVICE_NAME" '$0 ~ name && $0 ~ /Booted|Shutdown/ { gsub(/[()]/, "", $NF); print $NF; exit }')"

if [[ -z "${UDID}" ]]; then
  echo "[error] simulator not found: ${DEVICE_NAME}"
  exit 1
fi

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl list devices | grep "$UDID"
