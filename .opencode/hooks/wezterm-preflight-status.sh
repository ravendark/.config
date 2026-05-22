#!/bin/bash
# WezTerm preflight status hook for Claude Code
# Sets CLAUDE_STATUS user variable via OSC 1337 when user submits a lifecycle command,
# providing immediate in-progress tab coloring before Claude begins processing.
#
# Integration: Called from UserPromptSubmit hook in .claude/settings.json
#              Replaces wezterm-clear-status.sh in UserPromptSubmit hooks.
# Requirements: wezterm with user variable support, jq for JSON parsing
#
# 3-tier logic:
#   Tier 1 (SET in-progress): Lifecycle commands (/research, /plan, /implement)
#     /research N  -> CLAUDE_STATUS = "researching"
#     /plan N      -> CLAUDE_STATUS = "planning"
#     /implement N -> CLAUDE_STATUS = "implementing"
#   Tier 2 (CLEAR): Any other slash command (new context, no in-progress state)
#   Tier 3 (PRESERVE): Free text / follow-up (CLAUDE_STATUS unchanged)
#
# Note: Claude Code hooks run with redirected stdio (stdout is a socket),
# so we must write the escape sequence directly to the pane's TTY.

set -euo pipefail

# Helper: return success JSON for hook
exit_success() {
    echo '{}'
    exit 0
}

# Only run in WezTerm
if [[ -z "${WEZTERM_PANE:-}" ]]; then
    exit_success
fi

# Read hook input from stdin (Claude Code provides JSON)
HOOK_INPUT=$(cat)

# Parse user prompt from JSON input
PROMPT=$(echo "$HOOK_INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")

# 3-tier status logic
STATUS_VALUE=""
SHOULD_SET=0
SHOULD_CLEAR=0

# Tier 1: Lifecycle commands -> set in-progress CLAUDE_STATUS
# /research N  -> researching
# /plan N      -> planning
# /implement N -> implementing
if [[ "$PROMPT" =~ ^[[:space:]]*/?(research)[[:space:]]+ ]]; then
    STATUS_VALUE="researching"
    SHOULD_SET=1
elif [[ "$PROMPT" =~ ^[[:space:]]*/?(plan)[[:space:]]+ ]]; then
    STATUS_VALUE="planning"
    SHOULD_SET=1
elif [[ "$PROMPT" =~ ^[[:space:]]*/?(implement)[[:space:]]+ ]]; then
    STATUS_VALUE="implementing"
    SHOULD_SET=1

# Tier 2: Any other slash command -> clear CLAUDE_STATUS
elif [[ "$PROMPT" =~ ^[[:space:]]*/[a-zA-Z] ]]; then
    SHOULD_CLEAR=1

# Tier 3: Free text / follow-up -> preserve CLAUDE_STATUS (no-op)
fi

# Get the TTY for the current pane from WezTerm CLI
# Claude Code hooks have redirected stdio, so we cannot use /dev/tty
PANE_TTY=$(wezterm cli list --format=json 2>/dev/null | \
    jq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tty_name" 2>/dev/null || echo "")

# Check if we found a writable TTY
if [[ -z "$PANE_TTY" ]] || [[ ! -w "$PANE_TTY" ]]; then
    exit_success
fi

if [[ "$SHOULD_SET" -eq 1 ]]; then
    # Set CLAUDE_STATUS to in-progress lifecycle state via OSC 1337
    # Format: OSC 1337 ; SetUserVar=name=base64_value ST
    STATUS_ENCODED=$(echo -n "$STATUS_VALUE" | base64 | tr -d '\n')
    printf '\033]1337;SetUserVar=CLAUDE_STATUS=%s\007' "$STATUS_ENCODED" > "$PANE_TTY"
elif [[ "$SHOULD_CLEAR" -eq 1 ]]; then
    # Clear CLAUDE_STATUS on non-lifecycle slash commands
    printf '\033]1337;SetUserVar=CLAUDE_STATUS=\007' > "$PANE_TTY"
fi
# Tier 3: no-op (CLAUDE_STATUS preserved from previous state)

exit_success
