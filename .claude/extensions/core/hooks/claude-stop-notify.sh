#!/bin/bash
# Unified Stop hook for Claude Code: dual-dispatch notification with signal-file suppress pattern
#
# Architecture (dual-dispatch):
#   1. update-task-status.sh postflight fires TTS+wezterm IMMEDIATELY and writes signal file
#   2. This Stop hook checks the signal file:
#      - If signal exists: postflight already fired -> consume signal, exit silently (no duplicate)
#      - If no signal: interactive/non-lifecycle stop -> fire needs_input wezterm + "Tab N" TTS
#
# Signal file: .claude/tmp/lifecycle-signal
#   - Written by update-task-status.sh postflight (contains status string, e.g. "researched")
#   - Consumed atomically by this script using mv to prevent double-fire on concurrent invocations
#
# Subagent suppression:
#   - Stop hook fires for all agents (including subagents)
#   - If stdin JSON contains agent_id field, this is a subagent stop -> suppress all dispatch
#
# Integration: Called from Stop hook in .claude/settings.json
# Requirements: bash, jq (for subagent detection), wezterm (optional)
#
# See: task 588 (refactor_notification_signal_stop_hook)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Signal file paths
SIGNAL_FILE="$SCRIPT_DIR/../tmp/lifecycle-signal"
SIGNAL_CONSUMED="$SCRIPT_DIR/../tmp/lifecycle-signal.consumed"

# Helper: return success JSON for Stop hook
exit_success() {
    echo '{}'
    exit 0
}

# --- Subagent detection ---
# Read stdin JSON to check if this is a subagent stop event.
# If agent_id is present in the stop context, suppress all lifecycle dispatch.
STDIN_JSON=$(cat 2>/dev/null || echo '{}')
AGENT_ID=$(echo "$STDIN_JSON" | jq -r '.agent_id // empty' 2>/dev/null || echo "")
if [[ -n "$AGENT_ID" ]]; then
    # This is a subagent stop -- do not consume signal or fire TTS
    exit_success
fi

# --- Ensure tmp directory exists ---
mkdir -p "$SCRIPT_DIR/../tmp" 2>/dev/null || true

# --- Atomic signal consume ---
# Use mv (rename) which is atomic on the same filesystem.
# Only one concurrent Stop hook invocation can win; the loser falls through to needs_input path.
if mv "$SIGNAL_FILE" "$SIGNAL_CONSUMED" 2>/dev/null; then
    # Signal exists: postflight already fired TTS+wezterm for a lifecycle transition
    # Read the status from the consumed signal file
    STATUS=$(cat "$SIGNAL_CONSUMED" 2>/dev/null || echo "")
    rm -f "$SIGNAL_CONSUMED"

    # Signal was consumed -- postflight already announced TTS+wezterm
    # Exit silently (no duplicate dispatch)
    exit_success
fi

# --- No signal: interactive / non-lifecycle stop ---
# Fire needs_input wezterm color + interactive "Tab N" TTS
wezterm_script="$SCRIPT_DIR/wezterm-notify.sh"
if [[ -f "$wezterm_script" ]]; then
    bash "$wezterm_script" 2>/dev/null || true
fi

tts_script="$SCRIPT_DIR/tts-notify.sh"
if [[ -f "$tts_script" ]]; then
    bash "$tts_script" 2>/dev/null &
fi

exit_success
