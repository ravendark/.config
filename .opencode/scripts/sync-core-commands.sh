#!/usr/bin/env bash
# sync-core-commands.sh
# Propagate canonical core OpenCode command files from nvim source to all
# registered child projects. Run from any directory; uses absolute paths.
#
# Usage:
#   sync-core-commands.sh [--dry-run] [--check] [--commands cmd1,cmd2,...]
#
# Flags:
#   --dry-run    Show what would be copied without modifying files
#   --check      Report drift without fixing; exits 1 if drift detected
#   --commands   Comma-separated list of commands to sync (default: implement,research,plan)
#
# Exit codes:
#   0  All files up to date (or would be after --dry-run)
#   1  Drift detected (--check mode only)
#   2  Script error (missing source file, etc.)

set -euo pipefail

# -- Configuration -----------------------------------------------------------

NVIM_SOURCE="/home/benjamin/.config/nvim/.opencode/commands"

# Registry of child project .opencode/commands directories
# Add new projects here as needed
CHILD_PROJECTS=(
  "/home/benjamin/Projects/ProofChecker/.opencode/commands"
  "/home/benjamin/.dotfiles/.opencode/commands"
  "/home/benjamin/.config/zed/.opencode/commands"
  "/home/benjamin/Projects/ModelChecker/.opencode/commands"
  "/home/benjamin/Projects/protocol/.opencode/commands"
)

# Default core routing commands to sync
DEFAULT_COMMANDS="implement research plan"

# -- Parse arguments ---------------------------------------------------------

DRY_RUN=false
CHECK_ONLY=false
COMMANDS_TO_SYNC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --commands)
      shift
      if [[ $# -eq 0 ]]; then
        echo "[ERROR] --commands requires a value (e.g., --commands implement,research,plan)" >&2
        exit 2
      fi
      # Convert comma-separated to space-separated
      COMMANDS_TO_SYNC="${1//,/ }"
      shift
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,2\}//'
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

COMMANDS_TO_SYNC="${COMMANDS_TO_SYNC:-$DEFAULT_COMMANDS}"

# -- Validate source ---------------------------------------------------------

if [[ ! -d "$NVIM_SOURCE" ]]; then
  echo "[ERROR] Source directory not found: $NVIM_SOURCE" >&2
  exit 2
fi

for cmd in $COMMANDS_TO_SYNC; do
  src="$NVIM_SOURCE/${cmd}.md"
  if [[ ! -f "$src" ]]; then
    echo "[ERROR] Source file not found: $src" >&2
    exit 2
  fi
done

# -- Mode header -------------------------------------------------------------

if [[ "$DRY_RUN" = true ]]; then
  echo "[DRY RUN] sync-core-commands.sh — no files will be modified"
elif [[ "$CHECK_ONLY" = true ]]; then
  echo "[CHECK] sync-core-commands.sh — reporting drift only"
else
  echo "[SYNC] sync-core-commands.sh — propagating canonical commands"
fi
echo ""
echo "Source: $NVIM_SOURCE"
echo "Commands: $COMMANDS_TO_SYNC"
echo ""

# -- Execute sync ------------------------------------------------------------

total_checked=0
total_current=0
total_updated=0
total_skipped=0
drift_found=false

for project_dir in "${CHILD_PROJECTS[@]}"; do
  echo "--- $project_dir ---"

  if [[ ! -d "$project_dir" ]]; then
    echo "  [SKIP] Directory not found (project may not exist or has no .opencode/commands)"
    total_skipped=$((total_skipped + 1))
    continue
  fi

  if [[ ! -w "$project_dir" ]]; then
    echo "  [SKIP] Directory not writable"
    total_skipped=$((total_skipped + 1))
    continue
  fi

  for cmd in $COMMANDS_TO_SYNC; do
    src="$NVIM_SOURCE/${cmd}.md"
    dst="$project_dir/${cmd}.md"
    total_checked=$((total_checked + 1))

    if [[ -f "$dst" ]] && diff -q "$src" "$dst" > /dev/null 2>&1; then
      echo "  [OK]   ${cmd}.md — already current"
      total_current=$((total_current + 1))
    else
      if [[ "$CHECK_ONLY" = true ]]; then
        echo "  [DRIFT] ${cmd}.md — differs from canonical source"
        drift_found=true
      elif [[ "$DRY_RUN" = true ]]; then
        echo "  [WOULD UPDATE] ${cmd}.md"
        total_updated=$((total_updated + 1))
      else
        cp "$src" "$dst"
        echo "  [UPDATED] ${cmd}.md"
        total_updated=$((total_updated + 1))
      fi
    fi
  done
  echo ""
done

# -- Summary -----------------------------------------------------------------

echo "=== Summary ==="
echo "Projects:   ${#CHILD_PROJECTS[@]} registered"
echo "Skipped:    $total_skipped (missing or unwritable)"
echo "Checked:    $total_checked files"
echo "Current:    $total_current already up to date"
if [[ "$CHECK_ONLY" = true ]]; then
  if [[ "$drift_found" = true ]]; then
    echo "Drift:      YES — run without --check to fix"
    exit 1
  else
    echo "Drift:      none detected"
    exit 0
  fi
elif [[ "$DRY_RUN" = true ]]; then
  echo "Would update: $total_updated"
else
  echo "Updated:    $total_updated"
fi
