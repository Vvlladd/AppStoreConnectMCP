#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const root = path.resolve(__dirname, "..");

const packagePath = path.join(root, "package.json");
const serverPath = path.join(root, "server.json");
const projectPath = path.join(root, "Project.swift");

const usage = () => {
  console.error("Usage: npm run version:sync -- [--dry-run]");
};

const args = process.argv.slice(2);
const dryRun = args.includes("--dry-run");
if (args.length > 1 || (args.length === 1 && !dryRun)) {
  usage();
  process.exit(1);
}

const semverPattern = /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/;

const packageJson = JSON.parse(fs.readFileSync(packagePath, "utf8"));
const serverJson = JSON.parse(fs.readFileSync(serverPath, "utf8"));
const projectSwift = fs.readFileSync(projectPath, "utf8");

const readVersionByPattern = (content, pattern, sourceName, fieldName) => {
  const match = content.match(pattern);
  if (!match) {
    throw new Error(`Could not find ${fieldName} in ${sourceName}`);
  }
  const version = match[1];
  if (!semverPattern.test(version)) {
    throw new Error(`${sourceName} contains non-semver version '${version}'`);
  }
  return version;
};

const sourceVersion = readVersionByPattern(
  projectSwift,
  /\blet\s+mcpVersion\s*=\s*"([^"]+)"/,
  "Project.swift",
  "let mcpVersion = \"...\""
);

const npmEntry = Array.isArray(serverJson.packages)
  ? serverJson.packages.find((entry) => entry.registryType === "npm")
  : undefined;

if (!npmEntry) {
  throw new Error("server.json is missing packages[] entry with registryType='npm'");
}

const currentPackageVersion = packageJson.version;
const currentServerVersion = serverJson.version;
const currentNpmPackageVersion = npmEntry.version;

packageJson.version = sourceVersion;
serverJson.version = sourceVersion;
npmEntry.version = sourceVersion;

console.log(`Source: Project.swift (mcpVersion=${sourceVersion})`);
console.log(`Current: package=${currentPackageVersion}, server=${currentServerVersion}, npmPackage=${currentNpmPackageVersion}`);

if (dryRun) {
  console.log(`[dry-run] Would set all versions to ${sourceVersion}`);
  console.log(`[dry-run] Would update: ${packagePath}`);
  console.log(`[dry-run] Would update: ${serverPath}`);
  process.exit(0);
}

fs.writeFileSync(packagePath, `${JSON.stringify(packageJson, null, 2)}\n`);
fs.writeFileSync(serverPath, `${JSON.stringify(serverJson, null, 2)}\n`);

console.log(`Synced versions to ${sourceVersion}`);
console.log(`Updated ${packagePath}`);
console.log(`Updated ${serverPath}`);
