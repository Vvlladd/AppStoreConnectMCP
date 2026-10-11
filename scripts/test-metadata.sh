#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
SOURCES="$ROOT_DIR/Sources/AppStoreConnectMCP"
swiftc -swift-version 6 -parse-as-library -module-cache-path "$TEST_DIR/ModuleCache" \
  "$SOURCES/API/Endpoints.swift" \
  "$SOURCES/API/Models/APIResponse.swift" \
  "$SOURCES/API/Models/PreReleaseVersion.swift" \
  "$SOURCES/API/Models/App.swift" \
  "$SOURCES/API/Models/AppInfo.swift" \
  "$SOURCES/API/Models/AppInfoLocalization.swift" \
  "$SOURCES/API/Models/AppStoreVersion.swift" \
  "$SOURCES/API/Models/AppStoreVersionLocalization.swift" \
  "$SOURCES/Tools/MetadataFormatting.swift" \
  "$ROOT_DIR/scripts/test-metadata.swift" \
  -o "$TEST_DIR/test-metadata"
"$TEST_DIR/test-metadata"
