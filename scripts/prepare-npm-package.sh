#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY_PATH="$ROOT_DIR/dist/AppStoreConnectMCP"

if [[ ! -f "$BINARY_PATH" ]]; then
  echo "Missing $BINARY_PATH." >&2
  echo "Run 'npm run build:universal' before packing or publishing." >&2
  exit 1
fi

chmod 755 "$BINARY_PATH"

if command -v lipo >/dev/null 2>&1; then
  ARCHS="$(lipo -archs "$BINARY_PATH" 2>/dev/null || true)"
  if [[ "$ARCHS" != *"arm64"* || "$ARCHS" != *"x86_64"* ]]; then
    echo "Expected a universal binary (arm64 + x86_64). Found: ${ARCHS:-unknown}" >&2
    exit 1
  fi
fi

echo "npm package check passed for $BINARY_PATH"
