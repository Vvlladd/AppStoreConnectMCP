#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCTS="${1:-$ROOT_DIR/.build/npm-universal/arm64/Build/Products/Release}"
if [[ ! -d "$PRODUCTS/MCP.framework" ]]; then
  echo "Build the project first, then pass its Build/Products/Release directory." >&2
  exit 1
fi
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
SOURCES="$ROOT_DIR/Sources/AppStoreConnectMCP"
swiftc -swift-version 6 -parse-as-library -module-cache-path "$TEST_DIR/ModuleCache" \
  -F "$PRODUCTS" -framework MCP -framework Logging -framework SystemPackage \
  -framework EventSource -framework CSystem -lswiftSynchronization \
  "$SOURCES/API/Endpoints.swift" \
  "$SOURCES/API/Models/APIResponse.swift" \
  "$SOURCES/API/Models/APIError.swift" \
  "$SOURCES/API/Models/PreReleaseVersion.swift" \
  "$SOURCES/API/Models/App.swift" \
  "$SOURCES/API/Models/AppInfo.swift" \
  "$SOURCES/API/Models/AppInfoLocalization.swift" \
  "$SOURCES/API/Models/AppStoreVersion.swift" \
  "$SOURCES/API/Models/AppStoreVersionPhasedRelease.swift" \
  "$SOURCES/API/Models/AppStoreVersionLocalization.swift" \
  "$SOURCES/API/Models/Build.swift" \
  "$SOURCES/Tools/MetadataArguments.swift" \
  "$SOURCES/Tools/MetadataFormatting.swift" \
  "$SOURCES/Tools/PhasedReleaseManager.swift" \
  "$SOURCES/Tools/Handlers/ReleaseStatusHandler.swift" \
  "$SOURCES/Tools/Handlers/ValidateForSubmissionHandler.swift" \
  "$SOURCES/Tools/Handlers/UpdateAppInfoLocalizationHandler.swift" \
  "$ROOT_DIR/scripts/test-release-metadata.swift" \
  -o "$TEST_DIR/test-release-metadata"
"$TEST_DIR/test-release-metadata"
