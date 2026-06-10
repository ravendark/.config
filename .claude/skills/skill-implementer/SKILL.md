---
name: skill-implementer
description: Execute general implementation tasks following a plan. Invoke for general implementation work.
allowed-tools: Agent, Bash, Edit, Read, Write
---

# Implementer Skill

Thin wrapper that delegates general implementation to `general-implementation-agent` subagent.

**IMPORTANT**: Skill-internal postflight pattern — this skill handles all postflight operations after
the subagent returns, including the continuation loop for context-exhausted partial returns.

## Context References

Reference (do not load eagerly):
- `.claude/context/formats/return-metadata-file.md` - Metadata file schema
- `.claude/context/patterns/postflight-control.md` - Marker file protocol
- `.claude/context/patterns/subagent-continuation-loop.md` - Continuation loop pattern
- `.claude/context/patterns/context-exhaustion-detection.md` - Context exhaustion heuristics
- `.claude/context/patterns/jq-escaping-workarounds.md` - jq escaping patterns (Issue #1132)
- `.claude/scripts/update-phase-status.sh` - Phase-level status update script (called by subagent at phase boundaries)

---

## Execution Flow

### Stage 1: Input Validation

```bash
source .claude/scripts/skill-base.sh
skill_validate_input "$task_number"
# Exports: TASK_TYPE, TASK_STATUS, PROJECT_NAME, DESCRIPTION, PADDED_NUM, TASK_DIR
```

### Stage 2: Preflight Status Update

```bash
skill_preflight_update "$task_number" "implement" "$session_id"
```

The script atomically updates state.json, TODO.md (`[PLANNED]` -> `[IMPLEMENTING]`), and the plan file status.

### Stage 3: Create Postflight Marker

```bash
skill_create_postflight_marker "$PADDED_NUM" "$PROJECT_NAME" "$session_id" "skill-implementer" "implement"
```

### Stage 3a: Calculate Artifact Number

Implementer uses "prev" mode — shares the same round as research/plan.

```bash
skill_read_artifact_number "$task_number" "$PADDED_NUM" "$PROJECT_NAME" "summaries/" "prev"
# Exports: ARTIFACT_NUMBER, ARTIFACT_PADDED
```

**Note**: Implement does NOT increment `next_artifact_number`. Only research advances the sequence.

### Stage 4a: Clean Flag (Pass-Through)

Extract clean_flag for pass-through to subagent prompt. Do NOT run memory-retrieve.sh here — delegate to subagent.

```bash
clean_flag="${clean_flag:-false}"
```

### Stage 4: Prepare Delegation Context

Extract orchestrator_mode early (controls continuation loop behavior):

> **Cross-reference**: `orchestrator_mode=true` is set ONLY by `/orchestrate` command via
> `skill-orchestrate`. When true, the inner continuation loop is disabled (Stage 5c sets
> max_continuations=0) so the orchestrator state machine drives continuation.
> See: `.claude/skills/skill-orchestrate/SKILL.md` and `.claude/docs/architecture/orchestrate-state-machine.md`

```bash
orchestrator_mode=$(echo "$delegation_context" | jq -r '.orchestrator_mode // "false"' 2>/dev/null || echo "false")
```

Find the latest plan file to pass to the implementation agent:

```bash
plan_path=$(ls -1 "specs/${PADDED_NUM}_${PROJECT_NAME}/plans/"*.md 2>/dev/null | sort -V | tail -1)
```

**Note**: The subagent has access to `.claude/scripts/update-phase-status.sh` for phase-level status logging. It calls this script at phase boundaries (Stage 4A, 4D, 4E) alongside its Edit tool calls. The skill does not call this script — it is the subagent's responsibility.

Prepare delegation context for the subagent:

```json
{
  "session_id": "sess_{timestamp}_{random}",
  "delegation_depth": 1,
  "delegation_path": ["orchestrator", "implement", "skill-implementer"],
  "timeout": 7200,
  "task_context": {
    "task_number": N,
    "task_name": "{PROJECT_NAME}",
    "description": "{DESCRIPTION}",
    "task_type": "{TASK_TYPE}"
  },
  "artifact_number": "{ARTIFACT_PADDED}",
  "effort_flag": "{effort_flag or null}",
  "model_flag": "{model_flag or null}",
  "orchestrator_mode": false,
  "plan_path": "{plan_path}",
  "clean_flag": "{clean_flag}",
  "metadata_file_path": "specs/{NNN}_{SLUG}/.return-meta.json"
}
```

**Model/Effort Flags**: Pass `model_flag` as `model` parameter on the Agent tool if set. Include `effort_flag` as prompt context for reasoning depth if set.

> **CRITICAL: No Source Reading Before Delegation** — Between Stage 4 and Stage 5, this skill MUST NOT read, grep, glob, or analyze source files. All codebase exploration is the sub-agent's responsibility.

### Stage 5: Invoke Subagent

**CRITICAL**: Use the **Agent** tool (`subagent_type: "general-implementation-agent"`).

Build the prompt with these blocks in order:
1. Delegation context JSON
2. Task-specific instructions including:
   - "Follow the summary format in @.claude/context/formats/summary-format.md"
   - If `clean_flag` is not "true": "Run `bash .claude/scripts/memory-retrieve.sh '{DESCRIPTION}' '{TASK_TYPE}' ''` to retrieve relevant memories and incorporate them."

**DO NOT** use `Skill(general-implementation-agent)` — this will FAIL.

### Stage 5a: Validate Subagent Return Format

If the subagent's text return parses as valid JSON, log a warning (v1 pattern instead of v2 file-based pattern). Non-blocking — continue to read metadata file regardless.

### Stage 5b: Self-Execution Fallback

If you performed work WITHOUT using the Agent tool, write `.return-meta.json` with status `"implemented"` before proceeding to postflight. If you used the Agent tool, skip this stage.

### Stage 5c: Continuation Loop Init

Initialize continuation tracking before entering the postflight loop:

```bash
continuation_count=0
# When orchestrator_mode=true, disable inner continuation loop (orchestrator drives continuation)
if [ "$orchestrator_mode" = "true" ]; then
  max_continuations=0
else
  max_continuations=3
fi
task_dir="specs/${PADDED_NUM}_${PROJECT_NAME}"
cat > "${task_dir}/.continuation-loop-guard" << EOF
{
  "session_id": "${session_id}",
  "continuation_count": 0,
  "max_continuations": ${max_continuations},
  "orchestrator_mode": "${orchestrator_mode}",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

---

## Postflight (ALWAYS EXECUTE)

### Continuation Loop

```
while true; do
```

#### Stage 6: Read Metadata File

```bash
source .claude/scripts/skill-base.sh
skill_read_metadata "$PADDED_NUM" "$PROJECT_NAME"
# Exports: SUBAGENT_STATUS, ARTIFACT_PATH, ARTIFACT_TYPE, ARTIFACT_SUMMARY, MEMORY_CANDIDATES

# Read implementer-specific extra fields inline
meta_file="specs/${PADDED_NUM}_${PROJECT_NAME}/.return-meta.json"
if [ -f "$meta_file" ] && jq empty "$meta_file" 2>/dev/null; then
  phases_completed=$(jq -r '.metadata.phases_completed // 0' "$meta_file")
  phases_total=$(jq -r '.metadata.phases_total // 0' "$meta_file")
  completion_summary=$(jq -r '.completion_data.completion_summary // ""' "$meta_file")
  roadmap_items=$(jq -c '.completion_data.roadmap_items // []' "$meta_file")
  handoff_path=$(jq -r '.partial_progress.handoff_path // ""' "$meta_file")
fi
```

#### Stage 6a: Validate Artifact Content

```bash
skill_validate_artifact "$SUBAGENT_STATUS" "$ARTIFACT_PATH" "summary"
```

#### Stage 6b: Commit Phase Progress (Inside Loop)

```bash
git add -A
git commit -m "task ${task_number} phase ${phases_completed}: implementation progress

Session: ${session_id}
" || echo "Note: Nothing to commit or commit failed (non-blocking)"
```

**Optional cross-check** (non-blocking): After reading `phases_completed` from `.return-meta.json`, you can verify by counting `[COMPLETED]` headings in the plan file:
```bash
# Non-blocking verification -- count mismatch is informational only
actual_completed=$(grep -c "^### Phase.*\[COMPLETED\]" "$plan_path" 2>/dev/null || echo 0)
[ "$actual_completed" != "$phases_completed" ] && echo "Note: plan shows $actual_completed completed phases, metadata reports $phases_completed (non-blocking)"
```

#### Stage 7: Update Task Status (Postflight)

**If status is "implemented"**:

```bash
# Step 1: Update status via centralized script
skill_postflight_update "$task_number" "implement" "$session_id" "$SUBAGENT_STATUS" "$orchestrator_mode"

# Step 2: Add completion_summary
if [ -n "$completion_summary" ]; then
  jq --arg summary "$completion_summary" \
    '(.active_projects[] | select(.project_number == '"$task_number"')).completion_summary = $summary' \
    specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
fi

# Step 3: Add roadmap_items for non-meta tasks
if [ "$TASK_TYPE" != "meta" ] && [ "$roadmap_items" != "[]" ] && [ -n "$roadmap_items" ]; then
  jq --argjson items "$roadmap_items" \
    '(.active_projects[] | select(.project_number == '"$task_number"')).roadmap_items = $items' \
    specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
fi

# Step 4: Propagate memory candidates
skill_propagate_memory_candidates "$task_number" "$MEMORY_CANDIDATES"

# Step 5: Write orchestrator handoff (only if orchestrator_mode=true)
export ORCHESTRATOR_HANDOFF_PHASES_COMPLETED="$phases_completed"
export ORCHESTRATOR_HANDOFF_PHASES_TOTAL="$phases_total"
skill_write_orchestrator_handoff "$orchestrator_mode" "$PADDED_NUM" "$PROJECT_NAME" \
  "implement" "$SUBAGENT_STATUS" "$ARTIFACT_SUMMARY" "$ARTIFACT_PATH" "$ARTIFACT_TYPE" "none"
unset ORCHESTRATOR_HANDOFF_PHASES_COMPLETED ORCHESTRATOR_HANDOFF_PHASES_TOTAL
```

**Break loop** — proceed to Stage 8.

---

**If status is "partial"**:

Update resume point inline (centralized script maps implement to "completed" only):

```bash
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   --argjson phase "$phases_completed" \
  '(.active_projects[] | select(.project_number == '"$task_number"')) |= . + {
    last_updated: $ts,
    resume_phase: ($phase + 1)
  }' specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json

# Update plan file to [PARTIAL]
.claude/scripts/update-plan-status.sh "$task_number" "$PROJECT_NAME" "PARTIAL"
```

**Continuation decision**:

```bash
if [ -n "$handoff_path" ] && [ -f "$handoff_path" ] && [ "$continuation_count" -lt "$max_continuations" ]; then
  continuation_count=$((continuation_count + 1))
  jq --argjson count "$continuation_count" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.continuation_count = $count | .last_updated = $ts' \
    "${task_dir}/.continuation-loop-guard" > "${task_dir}/.continuation-loop-guard.tmp" \
    && mv "${task_dir}/.continuation-loop-guard.tmp" "${task_dir}/.continuation-loop-guard"

  echo "Spawning successor subagent (continuation $continuation_count/$max_continuations)"
  echo "Handoff: $handoff_path"

  # Spawn successor via Agent tool with updated delegation context:
  # - delegation_depth: incremented by 1
  # - continuation_context: { is_successor: true, continuation_number: N, handoff_path: ..., progress_path: ..., previous_phases_completed: N }
  continue
else
  [ -z "$handoff_path" ] && echo "Partial return with no handoff_path. User must re-run /implement."
  [ "$continuation_count" -ge "$max_continuations" ] && echo "Max continuations ($max_continuations) reached. Returning partial."

  # Write orchestrator handoff for partial status (with continuation_context if handoff_path exists)
  if [ -n "$handoff_path" ] && [ -f "$handoff_path" ]; then
    export ORCHESTRATOR_HANDOFF_CONTINUATION_JSON=$(printf '{"handoff_path":"%s","phases_completed":%s,"phases_total":%s,"orchestrator_mode":true}' \
      "$handoff_path" "$phases_completed" "$phases_total")
  fi
  export ORCHESTRATOR_HANDOFF_PHASES_COMPLETED="$phases_completed"
  export ORCHESTRATOR_HANDOFF_PHASES_TOTAL="$phases_total"
  skill_write_orchestrator_handoff "$orchestrator_mode" "$PADDED_NUM" "$PROJECT_NAME" \
    "implement" "partial" "$ARTIFACT_SUMMARY" "$ARTIFACT_PATH" "$ARTIFACT_TYPE" "implement"
  unset ORCHESTRATOR_HANDOFF_CONTINUATION_JSON ORCHESTRATOR_HANDOFF_PHASES_COMPLETED ORCHESTRATOR_HANDOFF_PHASES_TOTAL

  break
fi
```

---

**If status is "failed"**:

Keep status as "implementing" for retry. Break loop — proceed to Stage 8.

```
done  # End Continuation Loop
```

---

### Stage 8: Link Artifacts

```bash
skill_link_artifacts "$task_number" "$ARTIFACT_PATH" "$ARTIFACT_TYPE" "$ARTIFACT_SUMMARY" '**Summary**' '**Description**'
```

### Stage 9: Git Commit

```bash
git add -A
git commit -m "task ${task_number}: complete implementation

Session: ${session_id}"
```

### Stage 10: Cleanup

```bash
skill_cleanup "$PADDED_NUM" "$PROJECT_NAME"
rm -f "${task_dir}/.continuation-loop-guard"
```

### Stage 11: Return Brief Summary

Return a brief text summary (NOT JSON):
```
Implementation completed for task {N}:
- All {phases_total} phases executed successfully
- Created summary at specs/{NNN}_{SLUG}/summaries/MM_{short-slug}-summary.md
- Status updated to [COMPLETED]
- Changes committed
```

---

## Error Handling

- **Input validation errors**: Return immediately with error message
- **Metadata missing**: Keep status "implementing", do not cleanup marker, report to user
- **Git commit failure**: Non-blocking (log and continue)
- **Subagent timeout**: Return partial; keep "implementing" for resume

## MUST NOT (Context Protection)

Before delegating to the subagent, MUST NOT load file content into the lead context for passthrough. Specifically:

1. **MUST NOT `cat` format spec files** -- pass `@.claude/context/formats/summary-format.md` reference to subagent instead
2. **MUST NOT run `memory-retrieve.sh`** -- instruct subagent to run it in its own context

**Context budget target**: Lead context growth above baseline should stay under ~400 tokens for preflight.

Reference: @.claude/context/patterns/context-protective-lead.md

---

## Pre-Delegation Boundary

Before spawning the sub-agent, this skill MUST NOT read source files, grep/glob the codebase, use MCP tools, analyze source code, or run build/test commands.

Pre-delegation is LIMITED TO: reading the plan file path, extracting task context via jq, preparing delegation context, spawning the Agent.

## MUST NOT (Postflight Boundary)

After the agent returns, MUST NOT: read/edit source files, run build/test, use MCP tools, grep/glob codebase, or write summary/reports.

Continuation exception: if status is "partial" WITH a `handoff_path`, the skill MAY spawn a successor subagent (see Continuation Loop). Without `handoff_path`, report partial and let user re-run `/implement`.

Postflight is LIMITED TO: reading metadata, updating state.json, updating TODO.md, linking artifacts, git commit, cleanup.

Reference: @.claude/context/standards/postflight-tool-restrictions.md
