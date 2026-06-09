#!/usr/bin/env bash
# update-task-status.sh - Centralized task status update script
#
# Updates task status atomically across:
#   1. state.json (status field, timestamps, session_id)
#   2. TODO.md task entry (- **Status**: [STATUS])
#   3. TODO.md Task Order section (**{N}** [STATUS])
#   4. Plan file (for implement and plan operations, via update-plan-status.sh)
#
# Usage:
#   .claude/scripts/update-task-status.sh <operation> <task_number> <target_status> <session_id> [--dry-run]
#
# Arguments:
#   operation     - "preflight" or "postflight"
#   task_number   - Task number (integer)
#   target_status - "research", "plan", or "implement"
#   session_id    - Session identifier string
#
# Exit codes:
#   0 - Success or no-op (already at target status)
#   1 - Validation error (bad arguments)
#   2 - state.json update failed
#   3 - TODO.md update failed

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/specs/state.json"
TODO_FILE="$PROJECT_ROOT/specs/TODO.md"
TMP_DIR="$PROJECT_ROOT/specs/tmp"
LOCK_FILE="$PROJECT_ROOT/specs/.state.json.lock"

# --- Cleanup trap ---
cleanup() {
  rm -f "$TMP_DIR"/state.??????.json "$TMP_DIR"/todo.??????.md 2>/dev/null || true
}
trap cleanup EXIT

# --- Parse arguments ---
DRY_RUN=false
POSITIONAL_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) POSITIONAL_ARGS+=("$arg") ;;
  esac
done

operation="${POSITIONAL_ARGS[0]:-}"
task_number="${POSITIONAL_ARGS[1]:-}"
target_status="${POSITIONAL_ARGS[2]:-}"
session_id="${POSITIONAL_ARGS[3]:-}"

# --- Validation ---
if [[ -z "$operation" || -z "$task_number" || -z "$target_status" || -z "$session_id" ]]; then
  echo "Usage: $0 <operation> <task_number> <target_status> <session_id> [--dry-run]" >&2
  echo "  operation:     preflight | postflight" >&2
  echo "  target_status: research | plan | implement | revise" >&2
  exit 1
fi

if [[ "$operation" != "preflight" && "$operation" != "postflight" ]]; then
  echo "Error: operation must be 'preflight' or 'postflight', got '$operation'" >&2
  exit 1
fi

if [[ "$target_status" != "research" && "$target_status" != "plan" && "$target_status" != "implement" && "$target_status" != "revise" ]]; then
  echo "Error: target_status must be 'research', 'plan', 'implement', or 'revise', got '$target_status'" >&2
  exit 1
fi

if ! [[ "$task_number" =~ ^[0-9]+$ ]]; then
  echo "Error: task_number must be a positive integer, got '$task_number'" >&2
  exit 1
fi

if [[ ! -f "$STATE_FILE" ]]; then
  echo "Error: state.json not found at $STATE_FILE" >&2
  exit 1
fi

# --- Status mapping ---
map_status() {
  local op="$1"
  local target="$2"

  case "${op}:${target}" in
    preflight:research)   STATE_STATUS="researching";   TODO_STATUS="RESEARCHING" ;;
    preflight:plan)       STATE_STATUS="planning";      TODO_STATUS="PLANNING" ;;
    preflight:implement)  STATE_STATUS="implementing";  TODO_STATUS="IMPLEMENTING" ;;
    preflight:revise)     STATE_STATUS="revising";      TODO_STATUS="REVISING" ;;
    postflight:research)  STATE_STATUS="researched";    TODO_STATUS="RESEARCHED" ;;
    postflight:plan)      STATE_STATUS="planned";       TODO_STATUS="PLANNED" ;;
    postflight:implement) STATE_STATUS="completed";     TODO_STATUS="COMPLETED" ;;
    postflight:revise)    STATE_STATUS="revised";       TODO_STATUS="REVISED" ;;
    *)
      echo "Error: unknown operation:target_status combination '${op}:${target}'" >&2
      exit 1
      ;;
  esac
}

map_status "$operation" "$target_status"

# --- Validate task exists in state.json ---
task_exists=$(jq -r --arg num "$task_number" \
  '[.active_projects[] | select(.project_number == ($num | tonumber))] | length' \
  "$STATE_FILE")

if [[ "$task_exists" == "0" ]]; then
  echo "Error: task $task_number not found in state.json" >&2
  exit 1
fi

# --- Idempotency check ---
current_state_status=$(jq -r --arg num "$task_number" \
  '.active_projects[] | select(.project_number == ($num | tonumber)) | .status' \
  "$STATE_FILE")

if [[ "$current_state_status" == "$STATE_STATUS" ]]; then
  # Already at target status, no-op
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] Task $task_number already at status '$STATE_STATUS' -- no-op"
  fi
  exit 0
fi

# --- Ensure tmp directory exists ---
mkdir -p "$TMP_DIR"

# ============================================================
# PHASE 1: Update state.json (machine state first)
# ============================================================
update_state_json() {
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] state.json: task $task_number status '$current_state_status' -> '$STATE_STATUS'"
    echo "[dry-run] state.json: last_updated -> '$ts', session_id -> '$session_id'"
    return 0
  fi

  # Write workflow-active marker on preflight so Stop hook can suppress mid-workflow fires
  if [[ "$operation" == "preflight" ]]; then
    mkdir -p "$SCRIPT_DIR/../tmp"
    echo "$task_number $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$SCRIPT_DIR/../tmp/workflow-active"
  fi

  # Acquire exclusive lock around the entire read-jq-write critical section.
  # This prevents last-write-wins corruption when multiple agents call this script
  # concurrently during multi-task orchestration waves.
  (
    flock -x -w 30 200 || { echo "Error: could not acquire state.json lock (timeout after 30s)" >&2; return 1; }

    local tmp
    tmp=$(mktemp "$TMP_DIR/state.XXXXXX.json")

    # Use two-step jq pattern to avoid Issue #1132
    # Step 1: Update status and timestamp
    jq --arg num "$task_number" \
       --arg status "$STATE_STATUS" \
       --arg ts "$ts" \
       --arg sid "$session_id" \
      '(.active_projects[] | select(.project_number == ($num | tonumber))) |= . + {
        status: $status,
        last_updated: $ts,
        session_id: $sid
      }' "$STATE_FILE" > "$tmp"

    if [[ $? -ne 0 ]]; then
      echo "Error: jq failed to update state.json" >&2
      rm -f "$tmp"
      return 1
    fi

    # Validate the output is valid JSON
    if ! jq empty "$tmp" 2>/dev/null; then
      echo "Error: jq produced invalid JSON for state.json" >&2
      rm -f "$tmp"
      return 1
    fi

    # Atomic move
    mv "$tmp" "$STATE_FILE"
  ) 200>"$LOCK_FILE"
}

if ! update_state_json; then
  echo "Error: failed to update state.json for task $task_number" >&2
  exit 2
fi

# ============================================================
# PHASE 2: Update TODO.md task entry status
# ============================================================
update_todo_task_entry() {
  if [[ ! -f "$TODO_FILE" ]]; then
    echo "Warning: TODO.md not found at $TODO_FILE, skipping task entry update" >&2
    return 1
  fi

  # Find the task entry heading line number: ### {N}. ...
  local heading_line
  heading_line=$(grep -n "^### ${task_number}\." "$TODO_FILE" | head -1 | cut -d: -f1)

  if [[ -z "$heading_line" ]]; then
    echo "Warning: task $task_number entry not found in TODO.md Tasks section" >&2
    return 0
  fi

  # Find the Status line within the next 10 lines after the heading
  # Tolerant pattern: matches both canonical "- **Status**:" and space-indented " **Status**:"
  # Some task entries use space-indented format without leading dash
  local status_line
  status_line=$(sed -n "$((heading_line+1)),$((heading_line+10))p" "$TODO_FILE" \
    | grep -n -E '^\s*-?\s*\*\*Status\*\*: \[' | head -1 | cut -d: -f1)

  if [[ -z "$status_line" ]]; then
    echo "Warning: no Status line found for task $task_number in TODO.md" >&2
    return 0
  fi

  # Calculate actual line number in file
  local actual_line=$((heading_line + status_line))

  # Extract current status from the target line for idempotency check and dry-run display
  local current_todo_status
  current_todo_status=$(awk -v line="$actual_line" 'NR==line { match($0, /\[([A-Z ]+)\]/, arr); print arr[1]; exit }' "$TODO_FILE")

  if [[ "$current_todo_status" == "$TODO_STATUS" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "[dry-run] TODO.md task entry: already at [$TODO_STATUS] -- skip"
    fi
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] TODO.md task entry (line $actual_line): [$current_todo_status] -> [$TODO_STATUS]"
    return 0
  fi

  # Single-pass awk: replace any well-formed [STATUS] on the target line
  # sub() replaces first match; exit code reflects whether replacement was made
  local new_status="$TODO_STATUS"
  local replaced
  replaced=$(awk -v line="$actual_line" -v new_status="$new_status" '
    NR == line {
      if (sub(/\[[A-Z ]+\]/, "[" new_status "]")) {
        replaced = 1
      }
    }
    { print }
    END { exit (replaced ? 0 : 1) }
  ' "$TODO_FILE") || {
    echo "Warning: awk replacement found no [STATUS] pattern on line $actual_line of TODO.md task entry" >&2
    return 1
  }

  local tmp_todo
  tmp_todo=$(mktemp "$TMP_DIR/todo.XXXXXX.md")
  printf '%s\n' "$replaced" > "$tmp_todo"
  mv "$tmp_todo" "$TODO_FILE"
}

# ============================================================
# PHASE 3: Update TODO.md Task Order section
# ============================================================
update_todo_task_order() {
  if [[ ! -f "$TODO_FILE" ]]; then
    echo "Warning: TODO.md not found, skipping Task Order update" >&2
    return 1
  fi

  # Two-mode strategy per task-order-format.md:
  # Mode B: Terminal transitions (COMPLETED, ABANDONED) -> full regeneration via generate-task-order.sh
  # Mode A: Non-terminal transitions -> in-place sed on tree line
  if [[ "$TODO_STATUS" == "COMPLETED" || "$TODO_STATUS" == "ABANDONED" || "$TODO_STATUS" == "EXPANDED" ]]; then
    # Mode B: Full regeneration (auto-prunes completed task from tree and waves)
    local gen_script="$SCRIPT_DIR/generate-task-order.sh"
    if [[ -x "$gen_script" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] TODO.md Task Order: terminal status $TODO_STATUS -> would run generate-task-order.sh --update-todo"
        return 0
      fi
      "$gen_script" --update-todo "$TODO_FILE" "$STATE_FILE" || {
        echo "Warning: generate-task-order.sh failed (non-fatal)" >&2
      }
    else
      echo "Warning: generate-task-order.sh not found at $gen_script -- Task Order not regenerated" >&2
    fi
    return 0
  fi

  # Mode A: In-place status update for non-terminal transitions
  # Pattern matches tree lines at any indent level:
  #   "148 [RESEARCHED] — ..."          (root-level, no indent)
  #   "  └─ 147 [RESEARCHED] — ..."     (indented, depth 1)
  #   "    └─ 143 [PARTIAL] — ..."      (indented, depth 2)
  local order_line
  order_line=$(grep -n -E "^\s*(└─ )?${task_number} \[" "$TODO_FILE" | head -1 | cut -d: -f1)

  if [[ -z "$order_line" ]]; then
    echo "Warning: task $task_number not found in TODO.md Task Order tree -- falling back to full regeneration" >&2
    local gen_script="$SCRIPT_DIR/generate-task-order.sh"
    if [[ -x "$gen_script" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] TODO.md Task Order: task not in tree, would run generate-task-order.sh --update-todo"
        return 0
      fi
      "$gen_script" --update-todo "$TODO_FILE" "$STATE_FILE" 2>/dev/null || {
        echo "Warning: generate-task-order.sh fallback failed (non-fatal)" >&2
      }
    else
      echo "Warning: generate-task-order.sh not found at $gen_script -- Task Order not updated" >&2
    fi
    return 0
  fi

  # Extract current status from the target line for idempotency check and dry-run display
  local current_order_status
  current_order_status=$(awk -v line="$order_line" 'NR==line { match($0, /\[([A-Z ]+)\]/, arr); print arr[1]; exit }' "$TODO_FILE")

  if [[ "$current_order_status" == "$TODO_STATUS" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "[dry-run] TODO.md Task Order: already at [$TODO_STATUS] -- skip"
    fi
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] TODO.md Task Order (line $order_line): [$current_order_status] -> [$TODO_STATUS]"
    return 0
  fi

  # Single-pass awk: replace any well-formed [STATUS] on the target line
  # sub() replaces first match; exit code reflects whether replacement was made
  local new_status="$TODO_STATUS"
  local replaced
  replaced=$(awk -v line="$order_line" -v new_status="$new_status" '
    NR == line {
      if (sub(/\[[A-Z ]+\]/, "[" new_status "]")) {
        replaced = 1
      }
    }
    { print }
    END { exit (replaced ? 0 : 1) }
  ' "$TODO_FILE") || {
    echo "Warning: awk replacement found no [STATUS] pattern on line $order_line of TODO.md Task Order -- falling back to full regeneration" >&2
    local gen_script="$SCRIPT_DIR/generate-task-order.sh"
    if [[ -x "$gen_script" ]]; then
      "$gen_script" --update-todo "$TODO_FILE" "$STATE_FILE" 2>/dev/null || {
        echo "Warning: generate-task-order.sh fallback failed (non-fatal)" >&2
      }
    else
      echo "Warning: generate-task-order.sh not found at $gen_script -- Task Order not updated" >&2
    fi
    return 0
  }

  local tmp_todo
  tmp_todo=$(mktemp "$TMP_DIR/todo.XXXXXX.md")
  printf '%s\n' "$replaced" > "$tmp_todo"
  mv "$tmp_todo" "$TODO_FILE"
}

# ============================================================
# PHASE 4: Plan file status (optional, implement only)
# ============================================================
update_plan_file() {
  local plan_status
  case "${target_status}:${operation}" in
    implement:preflight)  plan_status="IMPLEMENTING" ;;
    implement:postflight) plan_status="COMPLETED" ;;
    plan:postflight)      plan_status="PLANNED" ;;
    *) return 0 ;;
  esac

  # Look up project_name from state.json
  local project_name
  project_name=$(jq -r --arg num "$task_number" \
    '.active_projects[] | select(.project_number == ($num | tonumber)) | .project_name' \
    "$STATE_FILE")

  if [[ -z "$project_name" || "$project_name" == "null" ]]; then
    echo "Warning: could not determine project_name for task $task_number" >&2
    return 0
  fi

  local plan_script="$SCRIPT_DIR/update-plan-status.sh"
  if [[ ! -x "$plan_script" ]]; then
    echo "Warning: update-plan-status.sh not found or not executable" >&2
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] Plan file: status -> [$plan_status] (via update-plan-status.sh)"
    return 0
  fi

  cd "$PROJECT_ROOT"
  local plan_output
  plan_output=$("$plan_script" "$task_number" "$project_name" "$plan_status" 2>&1) || {
    echo "Warning: plan file update failed: $plan_output" >&2
  }
}

# Execute TODO.md updates
todo_failed=false

if ! update_todo_task_entry; then
  todo_failed=true
fi

if ! update_todo_task_order; then
  todo_failed=true
fi

# Execute plan file update
update_plan_file

# ============================================================
# PHASE 5: Dual-dispatch lifecycle notifications (postflight only)
# Fires TTS and WezTerm tab coloring IMMEDIATELY from postflight so that
# notifications work even in never-stopping workflows (/loop, chained cmds).
# The Stop hook is suppressed during active workflows via workflow-active marker.
#
# See: task 601 (simplify_notification_pipeline_merge_vocabulary)
# ============================================================
if [[ "$operation" == "postflight" && "$DRY_RUN" != "true" ]]; then
  # Fire WezTerm tab color immediately using lifecycle STATE_STATUS directly
  wezterm_script="$SCRIPT_DIR/../hooks/wezterm-notify.sh"
  if [[ -x "$wezterm_script" ]] || [[ -f "$wezterm_script" ]]; then
    bash "$wezterm_script" "$STATE_STATUS" &
  fi

  # Fire TTS announcement immediately (speaks "Tab N STATUS")
  tts_script="$SCRIPT_DIR/../hooks/tts-notify.sh"
  if [[ -x "$tts_script" ]] || [[ -f "$tts_script" ]]; then
    bash "$tts_script" --lifecycle "$STATE_STATUS" &
  fi
fi

# Report result
if [[ "$todo_failed" == "true" && "$DRY_RUN" != "true" ]]; then
  echo "Warning: TODO.md updates had issues (state.json was updated successfully)" >&2
  exit 3
fi

if [[ "$DRY_RUN" != "true" ]]; then
  echo "OK: task $task_number status -> $STATE_STATUS"
fi

# --- Rename OpenCode session on preflight (no-op when no TUI running) ---
if [[ "$operation" == "preflight" && "$DRY_RUN" != "true" ]]; then
  project_name=$(jq -r --arg num "$task_number" \
    '.active_projects[] | select(.project_number == ($num | tonumber)) | .project_name' \
    "$STATE_FILE")
  label="$(echo "${target_status:0:1}" | tr '[:lower:]' '[:upper:]')${target_status:1}"
  rename_script="$SCRIPT_DIR/rename-session.sh"
  if [[ -x "$rename_script" ]]; then
    bash "$rename_script" "${label} task ${task_number}: ${project_name}" 2>/dev/null || true
  fi
fi

exit 0
