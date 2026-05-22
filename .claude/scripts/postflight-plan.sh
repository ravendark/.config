#!/bin/bash
# postflight-plan.sh — Thin wrapper for backward compatibility
#
# Usage: ./postflight-plan.sh TASK_NUMBER ARTIFACT_PATH [ARTIFACT_SUMMARY]
#
# This script is a thin wrapper around postflight-workflow.sh.
# It exists for backward compatibility until task 599 removes the wrappers.
# All logic now lives in .claude/scripts/postflight-workflow.sh.
#
# See: .claude/context/patterns/jq-escaping-workarounds.md

exec "$(dirname "$0")/postflight-workflow.sh" "$@" "plan"
