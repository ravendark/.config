#!/usr/bin/env bash
# validate-routing-tables.sh
# Validates that command routing tables include all task types declared in extension manifests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

MANIFEST_DIR="$PROJECT_ROOT/.opencode/extensions"
COMMANDS_DIR="$PROJECT_ROOT/.opencode/commands"

ERRORS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Routing Table Validation ==="
echo ""

# Step 1: Extract all task types from manifests
declare -A MANIFEST_TASKS
declare -A MANIFEST_SKILLS

for manifest in "$MANIFEST_DIR"/*/manifest.json; do
  if [ -f "$manifest" ]; then
    ext_name=$(basename "$(dirname "$manifest")")
    
    for routing_type in implement research plan; do
      task_types=$(jq -r --arg rt "$routing_type" '.routing[$rt] // {} | keys[]' "$manifest" 2>/dev/null || true)
      
      for task_type in $task_types; do
        skill=$(jq -r --arg rt "$routing_type" --arg tt "$task_type" '.routing[$rt][$tt] // empty' "$manifest")
        if [ -n "$skill" ]; then
          key="${routing_type}:${task_type}"
          MANIFEST_TASKS["$key"]="$ext_name"
          MANIFEST_SKILLS["$key"]="$skill"
        fi
      done
    done
  fi
done

echo "Found ${#MANIFEST_TASKS[@]} routing entries in manifests"
echo ""

# Step 2: Extract all task types from command docs
declare -A COMMAND_TASKS

for cmd in implement research plan; do
  cmd_file="$COMMANDS_DIR/${cmd}.md"
  if [ -f "$cmd_file" ]; then
    # Extract task types from the Extension-Based Routing Table section only
    # Look for the table header, then parse rows until empty line or new section
    in_table=false
    while IFS= read -r line; do
      # Detect table header
      if echo "$line" | grep -qE '^\| (Task Type|Language) \| Skill to Invoke \|'; then
        in_table=true
        continue
      fi
      # Detect end of table (empty line or non-table line after header)
      if [ "$in_table" = true ] && ! echo "$line" | grep -qE '^\|'; then
        in_table=false
        continue
      fi
      # Skip separator lines
      if echo "$line" | grep -qE '^\|[\-\|]+\|$'; then
        continue
      fi
      # Parse table row
      if [ "$in_table" = true ] && echo "$line" | grep -qE '^\| `[^`]+` \|'; then
        task_type=$(echo "$line" | sed -E 's/^\| `([^`]+)`.*/\1/')
        # Handle comma-separated types
        for tt in $(echo "$task_type" | tr ',' ' ' | tr -d '`'); do
          tt=$(echo "$tt" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          if [ -n "$tt" ] && [ "$tt" != "Task Type" ] && [ "$tt" != "Language" ]; then
            key="${cmd}:${tt}"
            COMMAND_TASKS["$key"]="found"
          fi
        done
      fi
    done < "$cmd_file"
  fi
done

echo "Found ${#COMMAND_TASKS[@]} routing entries in command docs"
echo ""

# Step 3: Compare - find manifest entries missing from command docs
echo "=== Checking for missing entries in command docs ==="
for key in "${!MANIFEST_TASKS[@]}"; do
  if [ -z "${COMMAND_TASKS[$key]+x}" ]; then
    IFS=':' read -r cmd task_type <<< "$key"
    ext_name="${MANIFEST_TASKS[$key]}"
    skill="${MANIFEST_SKILLS[$key]}"
    echo -e "${RED}MISSING${NC}: /${cmd} does not have '${task_type}' (from ${ext_name} extension -> ${skill})"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}All manifest entries found in command docs${NC}"
fi

echo ""

# Step 4: Compare - find command entries with no manifest
echo "=== Checking for orphaned entries in command docs ==="
ORPHANS=0
for key in "${!COMMAND_TASKS[@]}"; do
  if [ -z "${MANIFEST_TASKS[$key]+x}" ]; then
    IFS=':' read -r cmd task_type <<< "$key"
    # Skip generic fallbacks
    case "$task_type" in
      "general"|"meta"|"markdown"|"Other"|"founder:{sub-type}"|"present"|"lean"|"lean4"|"neovim"|"nix"|"typst"|"present:slides"|"slides")
        continue
        ;;
    esac
    echo -e "${YELLOW}ORPHAN${NC}: /${cmd} has '${task_type}' but no manifest declares it"
    ORPHANS=$((ORPHANS + 1))
  fi
done

if [ "$ORPHANS" -eq 0 ]; then
  echo -e "${GREEN}No orphaned entries found${NC}"
fi

echo ""
echo "=== Summary ==="
if [ "$ERRORS" -eq 0 ] && [ "$ORPHANS" -eq 0 ]; then
  echo -e "${GREEN}Validation passed${NC}: All routing tables are in sync with manifests"
  exit 0
else
  echo -e "${RED}Validation failed${NC}: $ERRORS missing, $ORPHANS orphaned"
  exit 1
fi
