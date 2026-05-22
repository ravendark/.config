#!/bin/bash
# WezTerm tab notification hook for OpenCode completion
# Sets CLAUDE_STATUS user variable via OSC 1337 when Claude stops
#
# Integration: Called from Stop hook in .opencode/settings.json
#              Also called by update-task-status.sh with lifecycle state parameter
# Requirements: wezterm with user variable support, jq for JSON parsing
#
# Usage:
#   bash wezterm-notify.sh              # Sets CLAUDE_STATUS=needs_input (Stop hook)
#   bash wezterm-notify.sh researched   # Sets CLAUDE_STATUS=researched (lifecycle)
#   bash wezterm-notify.sh completed    # Sets CLAUDE_STATUS=completed (lifecycle)
#
# Configuration:
#   WEZTERM_NOTIFY_ENABLED - Set to "0" to disable (default: 1)
#
# The CLAUDE_STATUS variable is read by wezterm.lua format-tab-title handler
# to show colored background on inactive tabs based on lifecycle state:
#   needs_input -> gray (default Stop behavior)
#   researched  -> dark green
#   planned     -> dark blue
#   completed   -> bright green
#   blocked     -> dark red
#   unknown     -> default styling (safe degradation)
#
# Note: Claude Code hooks run with redirected stdio (stdout is a socket),
# so we must write the escape sequence directly to the pane's TTY.

set -euo pipefail

# Configuration with defaults
WEZTERM_NOTIFY_ENABLED="${WEZTERM_NOTIFY_ENABLED:-1}"

# Parse optional lifecycle state parameter
# When called with an argument, use it as the CLAUDE_STATUS value
# When called without arguments (Stop hook), default to "needs_input"
STATUS="${1:-needs_input}"

# Helper: return success JSON for Stop hook
exit_success() {
    echo '{}'
    exit 0
}

# Check if notification is disabled
if [[ "$WEZTERM_NOTIFY_ENABLED" != "1" ]]; then
    exit_success
fi

# Only run in WezTerm
if [[ -z "${WEZTERM_PANE:-}" ]]; then
    exit_success
fi

# Get the TTY for the current pane from WezTerm CLI
# Claude Code hooks have redirected stdio, so we cannot use /dev/tty
PANE_TTY=$(wezterm cli list --format=json 2>/dev/null | \
    jq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tty_name" 2>/dev/null || echo "")

# Check if we found a writable TTY
if [[ -z "$PANE_TTY" ]] || [[ ! -w "$PANE_TTY" ]]; then
    exit_success
fi

# Set CLAUDE_STATUS user variable via OSC 1337
# Format: OSC 1337 ; SetUserVar=name=base64_value ST
# base64 encode the status value
STATUS_VALUE=$(echo -n "$STATUS" | base64 | tr -d '\n')

# Write OSC 1337 escape sequence to the pane's TTY (not stdout)
# \033] = OSC
# \007 = ST (string terminator)
printf '\033]1337;SetUserVar=CLAUDE_STATUS=%s\007' "$STATUS_VALUE" > "$PANE_TTY"

exit_success
