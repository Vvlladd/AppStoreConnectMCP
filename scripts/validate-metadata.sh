#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_JSON="$ROOT_DIR/package.json"
SERVER_JSON="$ROOT_DIR/server.json"
PROJECT_SWIFT="$ROOT_DIR/Project.swift"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required to validate MCP metadata." >&2
  exit 1
fi

node - "$PACKAGE_JSON" "$SERVER_JSON" "$PROJECT_SWIFT" <<'NODE'
const fs = require("node:fs");

const packagePath = process.argv[2];
const serverPath = process.argv[3];
const projectSwiftPath = process.argv[4];

const pkg = JSON.parse(fs.readFileSync(packagePath, "utf8"));
const server = JSON.parse(fs.readFileSync(serverPath, "utf8"));
const projectSwift = fs.readFileSync(projectSwiftPath, "utf8");

const errors = [];

if (pkg.mcpName !== server.name) {
  errors.push(`mcpName/name mismatch: package.json='${pkg.mcpName}' server.json='${server.name}'`);
}

if (pkg.version !== server.version) {
  errors.push(`version mismatch: package.json='${pkg.version}' server.json='${server.version}'`);
}

const npmPackage = Array.isArray(server.packages)
  ? server.packages.find((entry) => entry.registryType === "npm")
  : undefined;

if (!npmPackage) {
  errors.push("server.json is missing a packages[] entry with registryType='npm'");
} else {
  if (npmPackage.identifier !== pkg.name) {
    errors.push(`package identifier mismatch: package.json.name='${pkg.name}' server.json.packages[npm].identifier='${npmPackage.identifier}'`);
  }
  if (npmPackage.version !== pkg.version) {
    errors.push(`npm package version mismatch: package.json='${pkg.version}' server.json.packages[npm].version='${npmPackage.version}'`);
  }
}

const tuistVersionMatch = projectSwift.match(/\blet\s+mcpVersion\s*=\s*"([^"]+)"/);
if (!tuistVersionMatch) {
  errors.push("Could not find mcpVersion in Project.swift");
} else {
  const tuistVersion = tuistVersionMatch[1];
  if (tuistVersion !== pkg.version) {
    errors.push(`Project.swift version mismatch: package.json='${pkg.version}' Project.swift='${tuistVersion}'`);
  }
}

if (errors.length > 0) {
  console.error("MCP metadata validation failed:");
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log("MCP metadata check passed");
NODE
