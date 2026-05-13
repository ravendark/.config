#!/bin/bash
# TTS notification hook for Claude Code events
# Announces WezTerm tab number via Piper TTS when Claude stops or needs input
#
# Integration: Called from Stop and Notification hooks in .claude/settings.json
#              Also called directly by update-task-status.sh with --lifecycle flag
# Requirements: piper-tts, aplay (alsa-utils), jq, wezterm
#
# Supported Modes:
#   Normal (Stop/Notification hook) - "Tab N" or "Tab N worker"
#     Checks for lifecycle signal file; if present and fresh (<60s), consumes it
#     and skips TTS (lifecycle TTS already fired by postflight).
#   Lifecycle (--lifecycle STATUS) - "Tab N STATUS" (e.g., "Tab 3 researched")
#     Called by postflight scripts after successful status transitions.
#     Bypasses cooldown and stdin parsing for immediate lifecycle announcement.
#
# Configuration:
#   PIPER_MODEL - Path to piper voice model (default: ~/.local/share/piper/en_US-lessac-medium.onnx)
#   TTS_COOLDOWN - Seconds between notifications (default: 10)
#   TTS_ENABLED - Set to "0" to disable (default: 1)

set -uo pipefail

# Configuration with defaults
PIPER_MODEL="${PIPER_MODEL:-$HOME/.local/share/piper/en_US-lessac-medium.onnx}"
TTS_COOLDOWN="${TTS_COOLDOWN:-10}"
TTS_ENABLED="${TTS_ENABLED:-1}"

# State files
LAST_NOTIFY_FILE="specs/tmp/claude-tts-last-notify"
LOG_FILE="specs/tmp/claude-tts-notify.log"
LIFECYCLE_SIGNAL_FILE="specs/tmp/tts-lifecycle-signal"
LIFECYCLE_SIGNAL_MAX_AGE=60  # seconds before signal file is considered stale

# --- Parse arguments ---
LIFECYCLE_STATUS=""
if [[ "${1:-}" == "--lifecycle" ]] && [[ -n "${2:-}" ]]; then
    LIFECYCLE_STATUS="$2"
fi

# Helper: log message
log() {
    echo "[$(date -Iseconds)] $1" >> "$LOG_FILE"
}

# Helper: return success JSON for Stop hook
exit_success() {
    echo '{}'
    exit 0
}

# Helper: check if signal file exists and is fresh (age < max)
# Returns 0 if fresh signal file exists, 1 otherwise
# Sets SIGNAL_STATUS to the signal file content if fresh
check_signal_file() {
    SIGNAL_STATUS=""
    if [[ ! -f "$LIFECYCLE_SIGNAL_FILE" ]]; then
        return 1
    fi
    local file_time
    file_time=$(stat -c %Y "$LIFECYCLE_SIGNAL_FILE" 2>/dev/null || echo "0")
    local now
    now=$(date +%s)
    local age=$((now - file_time))
    if (( age >= LIFECYCLE_SIGNAL_MAX_AGE )); then
        # Stale signal file -- delete and treat as absent
        log "Stale lifecycle signal file (age=${age}s >= ${LIFECYCLE_SIGNAL_MAX_AGE}s) - deleting"
        rm -f "$LIFECYCLE_SIGNAL_FILE"
        return 1
    fi
    SIGNAL_STATUS=$(cat "$LIFECYCLE_SIGNAL_FILE" 2>/dev/null || echo "")
    return 0
}

# Helper: consume (delete) signal file
consume_signal_file() {
    rm -f "$LIFECYCLE_SIGNAL_FILE"
}

# Check if TTS is disabled
if [[ "$TTS_ENABLED" != "1" ]]; then
    exit_success
fi

# Check if piper is available
if ! command -v piper &>/dev/null; then
    log "piper command not found - skipping TTS notification"
    exit_success
fi

# Check if model exists
if [[ ! -f "$PIPER_MODEL" ]]; then
    log "Piper model not found at $PIPER_MODEL - skipping TTS notification"
    exit_success
fi

# ============================================================
# LIFECYCLE MODE: --lifecycle STATUS
# Skip stdin parsing, skip cooldown, speak "Tab N STATUS"
# ============================================================
if [[ -n "$LIFECYCLE_STATUS" ]]; then
    # Get WezTerm tab info for lifecycle announcement
    TAB_PREFIX="Tab"
    if [[ -n "${WEZTERM_PANE:-}" ]] && command -v wezterm &>/dev/null; then
        ALL_PANES=$(wezterm cli list --format=json 2>/dev/null)
        CURRENT_TAB_ID=$(echo "$ALL_PANES" | jq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tab_id" 2>/dev/null || echo "")
        if [[ -n "$CURRENT_TAB_ID" ]] && ! [[ "$CURRENT_TAB_ID" == "null" ]]; then
            UNIQUE_TAB_IDS=$(echo "$ALL_PANES" | jq -r '[.[].tab_id] | unique | .[]')
            TAB_INDEX=0
            POSITION=0
            while IFS= read -r tab_id; do
                if [[ "$tab_id" == "$CURRENT_TAB_ID" ]]; then
                    POSITION=$TAB_INDEX
                    break
                fi
                ((TAB_INDEX++))
            done <<< "$UNIQUE_TAB_IDS"
            TAB_NUM=$((POSITION + 1))
            TAB_PREFIX="Tab $TAB_NUM"
        fi
    fi

    MESSAGE="$TAB_PREFIX $LIFECYCLE_STATUS"

    # Speak using piper (background, tolerant of errors)
    if command -v paplay &>/dev/null; then
        TEMP_WAV="specs/tmp/claude-tts-$$.wav"
        (timeout 10s bash -c "echo '$MESSAGE' | piper --model '$PIPER_MODEL' --output_file '$TEMP_WAV' 2>/dev/null && paplay '$TEMP_WAV' 2>/dev/null; rm -f '$TEMP_WAV'" &) || true
    elif command -v aplay &>/dev/null; then
        (timeout 10s bash -c "echo '$MESSAGE' | piper --model '$PIPER_MODEL' --output_file - 2>/dev/null | aplay -q 2>/dev/null" &) || true
    else
        log "No audio player found (aplay or paplay) - skipping TTS notification"
        exit_success
    fi

    log "Lifecycle notification sent: $MESSAGE (status=$LIFECYCLE_STATUS)"
    exit_success
fi

# ============================================================
# NORMAL MODE: Stop / Notification hook
# Read stdin, check signal file, respect cooldown
# ============================================================

# Read stdin JSON (hooks provide context via stdin)
# Use timeout to avoid hanging if no stdin is available
STDIN_JSON=""
if read -t 0.1 -r line; then
    STDIN_JSON="$line"
    # Read any remaining lines
    while read -t 0.1 -r more; do
        STDIN_JSON="${STDIN_JSON}${more}"
    done
fi

# Parse event type and notification type from stdin JSON
HOOK_EVENT_NAME=""
NOTIFICATION_TYPE=""
if [[ -n "$STDIN_JSON" ]] && command -v jq &>/dev/null; then
    HOOK_EVENT_NAME=$(echo "$STDIN_JSON" | jq -r '.hook_event_name // empty' 2>/dev/null || echo "")
    NOTIFICATION_TYPE=$(echo "$STDIN_JSON" | jq -r '.notification_type // empty' 2>/dev/null || echo "")
fi

# Guard: suppress TTS for subagent contexts
# agent_id is present in hook stdin JSON only for subagents
if [[ -n "$STDIN_JSON" ]] && command -v jq &>/dev/null; then
    AGENT_ID=$(echo "$STDIN_JSON" | jq -r '.agent_id // empty' 2>/dev/null || echo "")
    if [[ -n "$AGENT_ID" ]]; then
        log "Subagent detected (agent_id=$AGENT_ID) - suppressing TTS"
        exit_success
    fi
fi

# Guard: filter non-actionable notification types
if [[ "$NOTIFICATION_TYPE" == "auth_success" ]]; then
    log "Non-actionable notification type ($NOTIFICATION_TYPE) - suppressing TTS"
    exit_success
fi

# Signal file check: if a lifecycle TTS was already fired by postflight,
# consume the signal file and skip the redundant Stop hook TTS
if check_signal_file; then
    log "Lifecycle signal file found (status=$SIGNAL_STATUS) - consuming and skipping Stop TTS"
    consume_signal_file
    exit_success
fi

# Check cooldown (simple time-based)
if [[ -f "$LAST_NOTIFY_FILE" ]]; then
    LAST_TIME=$(cat "$LAST_NOTIFY_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    ELAPSED=$((NOW - LAST_TIME))
    if (( ELAPSED < TTS_COOLDOWN )); then
        log "Cooldown active: ${ELAPSED}s < ${TTS_COOLDOWN}s - skipping notification"
        exit_success
    fi
fi

# Get WezTerm tab info
TAB_LABEL=""
if [[ -n "${WEZTERM_PANE:-}" ]] && command -v wezterm &>/dev/null; then
    # Get all panes data
    ALL_PANES=$(wezterm cli list --format=json 2>/dev/null)

    # Get the tab_id for the current pane
    CURRENT_TAB_ID=$(echo "$ALL_PANES" | jq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tab_id" 2>/dev/null || echo "")

    # Check if we got a valid tab_id (workaround for != escaping bug)
    if [[ -n "$CURRENT_TAB_ID" ]] && ! [[ "$CURRENT_TAB_ID" == "null" ]]; then
        # Get list of unique tab_ids in the order they appear
        # WezTerm lists panes in tab order, so first occurrence gives us the position
        UNIQUE_TAB_IDS=$(echo "$ALL_PANES" | jq -r '[.[].tab_id] | unique | .[]')

        # Find the position (0-indexed) of current tab
        TAB_INDEX=0
        POSITION=0
        while IFS= read -r tab_id; do
            if [[ "$tab_id" == "$CURRENT_TAB_ID" ]]; then
                POSITION=$TAB_INDEX
                break
            fi
            ((TAB_INDEX++))
        done <<< "$UNIQUE_TAB_IDS"

        # Convert to 1-indexed for display
        TAB_NUM=$((POSITION + 1))
        TAB_LABEL="Tab $TAB_NUM: "
    fi
fi

# Detect if running inside a git worktree (sub-agent session)
IS_WORKTREE=false
if command -v git &>/dev/null; then
    GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
    GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null)
    # In main worktree: both return same path (typically ".git")
    # In linked worktree: git-dir returns ".git/worktrees/<name>", common-dir returns main ".git"
    if [[ -n "$GIT_DIR" ]] && [[ -n "$GIT_COMMON_DIR" ]] && [[ "$GIT_DIR" != "$GIT_COMMON_DIR" ]]; then
        IS_WORKTREE=true
    fi
fi

# Build message based on event type
TAB_PREFIX="${TAB_LABEL%: }"  # Strip ": " suffix if present
if [[ -z "$TAB_PREFIX" ]]; then
    TAB_PREFIX="Tab"  # Fallback if tab detection failed
fi

# Append "worker" suffix for worktree (sub-agent) sessions
if [[ "$IS_WORKTREE" == "true" ]]; then
    MESSAGE="$TAB_PREFIX worker"
else
    MESSAGE="$TAB_PREFIX"
fi

# Speak using piper with paplay (background, tolerant of errors)
if command -v paplay &>/dev/null; then
    # paplay available (PulseAudio) - need to write to temp file first
    TEMP_WAV="specs/tmp/claude-tts-$$.wav"
    (timeout 10s bash -c "echo '$MESSAGE' | piper --model '$PIPER_MODEL' --output_file '$TEMP_WAV' 2>/dev/null && paplay '$TEMP_WAV' 2>/dev/null; rm -f '$TEMP_WAV'" &) || true
elif command -v aplay &>/dev/null; then
    # aplay available (ALSA)
    (timeout 10s bash -c "echo '$MESSAGE' | piper --model '$PIPER_MODEL' --output_file - 2>/dev/null | aplay -q 2>/dev/null" &) || true
else
    log "No audio player found (aplay or paplay) - skipping TTS notification"
    exit_success
fi

# Update cooldown timestamp
date +%s > "$LAST_NOTIFY_FILE"

log "Notification sent: $MESSAGE (worktree=$IS_WORKTREE)"

exit_success
