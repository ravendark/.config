---
name: skill-planner
description: Create phased implementation plans from research findings. Invoke when a task needs an implementation plan.
allowed-tools: Agent, Bash, Edit, Read, Write
---

# Planner Skill

Thin wrapper that delegates plan creation to `planner-agent` subagent.

**IMPORTANT**: Skill-internal postflight pattern — this skill handles all postflight operations after
the subagent returns, eliminating the "continue" prompt issue.

## Context References

Reference (do not load eagerly):
- `.claude/context/formats/return-metadata-file.md` - Metadata file schema
- `.claude/context/patterns/postflight-control.md` - Marker file protocol
- `.claude/context/patterns/jq-escaping-workarounds.md` - jq escaping patterns (Issue #1132)

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
skill_preflight_update "$task_number" "plan" "$session_id"
```

If the script exits non-zero, stop execution. Exit code 2 = state.json failure; exit code 3 = TODO.md failure.

### Stage 3: Create Postflight Marker

```bash
skill_create_postflight_marker "$PADDED_NUM" "$PROJECT_NAME" "$session_id" "skill-planner" "plan"
```

### Stage 3a: Calculate Artifact Number

Planner uses "prev" mode — shares the same round as the preceding research.

```bash
skill_read_artifact_number "$task_number" "$PADDED_NUM" "$PROJECT_NAME" "plans/" "prev"
# Exports: ARTIFACT_NUMBER, ARTIFACT_PADDED
```

**Note**: Plan does NOT increment `next_artifact_number`. Only research advances the sequence.

### Stage 4a: Memory Retrieval (Auto)

Skip if `clean_flag` is true.

```bash
memory_context=""
if [ "$clean_flag" != "true" ]; then
  memory_context=$(bash .claude/scripts/memory-retrieve.sh "$DESCRIPTION" "$TASK_TYPE" "" 2>/dev/null) || memory_context=""
fi
```

### Stage 4: Prepare Delegation Context

Extract orchestrator_mode early:

```bash
orchestrator_mode=$(echo "$delegation_context" | jq -r '.orchestrator_mode // "false"' 2>/dev/null || echo "false")
```

**Prior plan discovery**: Find the latest existing plan file (if any) to pass as reference context.

```bash
prior_plan_path=$(ls -1 "specs/${PADDED_NUM}_${PROJECT_NAME}/plans/"*.md 2>/dev/null | sort -V | tail -1)
# prior_plan_path will be empty if no prior plans exist
```

Prepare delegation context for the subagent:

```json
{
  "session_id": "sess_{timestamp}_{random}",
  "delegation_depth": 1,
  "delegation_path": ["orchestrator", "plan", "skill-planner"],
  "timeout": 1800,
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
  "roadmap_flag": "{roadmap_flag or false}",
  "research_path": "{path to research report if exists}",
  "prior_plan_path": "{prior_plan_path or empty}",
  "roadmap_path": "specs/ROADMAP.md",
  "metadata_file_path": "specs/{NNN}_{SLUG}/.return-meta.json"
}
```

**Model/Effort Flags**: Pass `model_flag` as `model` parameter on the Agent tool if set. Include `effort_flag` as prompt context for reasoning depth if set.

### Stage 4b: Read and Inject Format Specification

```bash
format_content=$(cat .claude/context/formats/plan-format.md)
```

### Stage 5: Invoke Subagent

**CRITICAL**: Use the **Agent** tool (`subagent_type: "planner-agent"`).

Build the prompt with these blocks in order:
1. Delegation context JSON
2. `<artifact-format-specification>` block with `{format_content}` (Plan Format Requirements)
3. `{memory_context}` block (only if non-empty; already wrapped in `<memory-context>` tags)
4. Task-specific instructions

**DO NOT** use `Skill(planner-agent)` or `Agent(subagent_type: "Plan")` — `Plan` is a built-in read-only subagent that CANNOT write files.

### Stage 5b: Self-Execution Fallback

If you performed work WITHOUT using the Agent tool, write `.return-meta.json` with status `"planned"` before proceeding to postflight. If you used the Agent tool, skip this stage.

---

## Postflight (ALWAYS EXECUTE)

### Stage 6: Read Metadata File

```bash
source .claude/scripts/skill-base.sh
skill_read_metadata "$PADDED_NUM" "$PROJECT_NAME"
# Exports: SUBAGENT_STATUS, ARTIFACT_PATH, ARTIFACT_TYPE, ARTIFACT_SUMMARY, MEMORY_CANDIDATES
```

### Stage 6a: Validate Artifact Content

```bash
skill_validate_artifact "$SUBAGENT_STATUS" "$ARTIFACT_PATH" "plan"
```

### Stage 7: Update Task Status (Postflight)

```bash
# Step 1: Update status
skill_postflight_update "$task_number" "plan" "$session_id" "$SUBAGENT_STATUS"

# Step 2: Write orchestrator handoff (only if orchestrator_mode=true)
skill_write_orchestrator_handoff "$orchestrator_mode" "$PADDED_NUM" "$PROJECT_NAME" \
  "plan" "$SUBAGENT_STATUS" "$ARTIFACT_SUMMARY" "$ARTIFACT_PATH" "$ARTIFACT_TYPE" "implement"
```

**On partial/failed**: `skill_postflight_update` skips non-success statuses — status remains "planning" for resume.

### Stage 8: Link Artifacts

```bash
skill_link_artifacts "$task_number" "$ARTIFACT_PATH" "$ARTIFACT_TYPE" "$ARTIFACT_SUMMARY" '**Plan**' '**Description**'
```

### Stage 9: Git Commit

```bash
git add -A
git commit -m "task ${task_number}: create implementation plan

Session: ${session_id}"
```

### Stage 10: Cleanup

```bash
skill_cleanup "$PADDED_NUM" "$PROJECT_NAME"
```

### Stage 11: Return Brief Summary

Return a brief text summary (NOT JSON):
```
Plan created for task {N}:
- {phase_count} phases defined, {estimated_hours} hours estimated
- Created plan at specs/{NNN}_{SLUG}/plans/MM_{short-slug}.md
- Status updated to [PLANNED]
- Changes committed
```

---

## Error Handling

- **Task not found or terminal state**: Exit immediately with error
- **Metadata missing**: Keep status "planning", do not cleanup marker, report error
- **Git commit failure**: Non-blocking (log and continue)
- **jq parse failure** (Issue #1132): Log to errors.json, retry with two-step pattern (already in skill_link_artifacts)
- **Subagent timeout**: Return partial; keep status "planning" for resume

---

## MUST NOT (Postflight Boundary)

After the agent returns, MUST NOT: edit source files, run build/test, use research tools, analyze task requirements, or write plan files.

Postflight is LIMITED TO: reading metadata, calling update-task-status.sh, linking artifacts, git commit, cleanup.

Reference: @.claude/context/standards/postflight-tool-restrictions.md
