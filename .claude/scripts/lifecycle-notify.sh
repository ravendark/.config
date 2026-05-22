#!/bin/bash
# lifecycle-notify.sh - DEPRECATED: notifications now handled by dual-dispatch architecture
#
# This stub is kept for backward compatibility. It is a no-op.
# Old skill files that call this script (via Stage 8a) will silently succeed.
#
# Architecture change (task 588 - refactor_notification_signal_stop_hook):
#   - update-task-status.sh postflight now fires TTS+wezterm IMMEDIATELY
#   - claude-stop-notify.sh Stop hook uses signal file to suppress duplicate dispatch
#   - Stage 8a blocks removed from skill files (skill-researcher, skill-planner,
#     skill-implementer, skill-reviser)
#
# See: .claude/hooks/claude-stop-notify.sh and .claude/scripts/update-task-status.sh

exit 0
