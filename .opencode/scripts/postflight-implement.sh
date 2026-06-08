#!/bin/bash
# postflight-implement.sh — Thin wrapper for backward compatibility
#
# Usage: ./postflight-implement.sh TASK_NUMBER ARTIFACT_PATH [ARTIFACT_SUMMARY]
#
# This script is a thin wrapper around postflight-workflow.sh.
# All logic now lives in .opencode/scripts/postflight-workflow.sh.
#
# See: .opencode/context/patterns/jq-escaping-workarounds.md

exec "$(dirname "$0")/postflight-workflow.sh" "$@" "implement"
