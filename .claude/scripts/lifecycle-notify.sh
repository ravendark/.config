#!/bin/bash
# lifecycle-notify.sh - Fire TTS and WezTerm notifications after lifecycle status transitions
# Called by skill postflight stages after artifact linking.
#
# Usage: bash lifecycle-notify.sh STATUS
# STATUS: researched | planned | completed | partial | blocked
#
# Non-blocking: runs tts-notify.sh and wezterm-notify.sh in background.
# Gracefully no-ops if either script is unavailable.

STATUS="${1:-}"
if [[ -z "$STATUS" ]]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/../hooks"

# TTS announcement (non-blocking)
tts_script="$HOOKS_DIR/tts-notify.sh"
if [[ -f "$tts_script" ]]; then
    bash "$tts_script" --lifecycle "$STATUS" &
fi

# WezTerm tab coloring (non-blocking)
wezterm_script="$HOOKS_DIR/wezterm-notify.sh"
if [[ -f "$wezterm_script" ]]; then
    bash "$wezterm_script" "$STATUS" &
fi

exit 0
