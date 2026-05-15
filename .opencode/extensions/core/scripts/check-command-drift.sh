#!/usr/bin/env bash
# check-command-drift.sh
# Detect drift between active OpenCode commands and the core extension source.
#
# Usage:
#   check-command-drift.sh [BASE_DIR]
#
# Arguments:
#   BASE_DIR  Path to the .opencode directory (default: auto-detect from script location)
#
# Exit codes:
#   0  No drift detected -- active commands match extension source
#   1  Drift detected -- see output for details
#   2  Usage error or missing directories
#
# Description:
#   Compares each .md file in {BASE_DIR}/commands/ against the corresponding file
#   in {BASE_DIR}/extensions/core/commands/. Reports:
#     - Files that differ (content mismatch)
#     - Files present in active commands but missing from extension source
#     - Files present in extension source but missing from active commands
#     - Commands listed in manifest.json but missing from either location

set -euo pipefail

# Resolve base directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ $# -ge 1 ]; then
  BASE_DIR="$1"
else
  # Auto-detect: scripts live in {BASE_DIR}/scripts/
  BASE_DIR="$(dirname "$SCRIPT_DIR")"
fi

ACTIVE_DIR="${BASE_DIR}/commands"
SOURCE_DIR="${BASE_DIR}/extensions/core/commands"
MANIFEST="${BASE_DIR}/extensions/core/manifest.json"

# Validate directories exist
if [ ! -d "$ACTIVE_DIR" ]; then
  echo "ERROR: Active commands directory not found: ${ACTIVE_DIR}" >&2
  exit 2
fi
if [ ! -d "$SOURCE_DIR" ]; then
  echo "ERROR: Extension source commands directory not found: ${SOURCE_DIR}" >&2
  exit 2
fi

drift_found=0

echo "Checking command drift: ${ACTIVE_DIR} vs ${SOURCE_DIR}"
echo ""

# 1. Compare each active command against extension source
echo "=== Content Comparison ==="
while IFS= read -r -d '' active_file; do
  filename="$(basename "$active_file")"
  # Skip non-command files
  [ "$filename" = "README.md" ] && continue

  source_file="${SOURCE_DIR}/${filename}"
  if [ ! -f "$source_file" ]; then
    echo "ONLY-IN-ACTIVE: ${filename}"
    drift_found=1
  elif ! diff -q "$active_file" "$source_file" > /dev/null 2>&1; then
    active_size="$(wc -c < "$active_file" | tr -d ' ')"
    source_size="$(wc -c < "$source_file" | tr -d ' ')"
    echo "DIFFERS: ${filename} (active: ${active_size}B, source: ${source_size}B)"
    drift_found=1
  fi
done < <(find "$ACTIVE_DIR" -maxdepth 1 -name "*.md" -print0 | sort -z)

# 2. Check for files in extension source not in active
while IFS= read -r -d '' source_file; do
  filename="$(basename "$source_file")"
  active_file="${ACTIVE_DIR}/${filename}"
  if [ ! -f "$active_file" ]; then
    echo "ONLY-IN-SOURCE: ${filename}"
    drift_found=1
  fi
done < <(find "$SOURCE_DIR" -maxdepth 1 -name "*.md" -print0 | sort -z)

if [ "$drift_found" -eq 0 ]; then
  echo "  (no content drift)"
fi

# 3. Cross-check manifest completeness
if [ -f "$MANIFEST" ] && command -v jq > /dev/null 2>&1; then
  echo ""
  echo "=== Manifest Completeness Check ==="
  manifest_drift=0

  while IFS= read -r cmd_file; do
    source_file="${SOURCE_DIR}/${cmd_file}"
    active_file="${ACTIVE_DIR}/${cmd_file}"

    if [ ! -f "$source_file" ]; then
      echo "MANIFEST-NOT-IN-SOURCE: ${cmd_file}"
      manifest_drift=1
      drift_found=1
    fi
    if [ ! -f "$active_file" ]; then
      echo "MANIFEST-NOT-IN-ACTIVE: ${cmd_file}"
      manifest_drift=1
      drift_found=1
    fi
  done < <(jq -r '.provides.commands[]' "$MANIFEST" 2>/dev/null | sort)

  if [ "$manifest_drift" -eq 0 ]; then
    echo "  (manifest matches source and active)"
  fi
else
  echo ""
  echo "=== Manifest Check Skipped (jq not available or manifest missing) ==="
fi

# Summary
echo ""
if [ "$drift_found" -eq 0 ]; then
  echo "OK: No drift detected."
  exit 0
else
  echo "DRIFT DETECTED: Run the following to sync:"
  echo "  cp ${ACTIVE_DIR}/*.md ${SOURCE_DIR}/"
  exit 1
fi
