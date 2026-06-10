---
name: skill-researcher
description: Conduct general research using web search, documentation, and codebase exploration. Invoke for general research tasks.
allowed-tools: Agent, Bash, Edit, Read, Write
---

# Researcher Skill

Thin wrapper that delegates general research to `general-research-agent` subagent.

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
skill_preflight_update "$task_number" "research" "$session_id"
```

### Stage 3: Create Postflight Marker

```bash
skill_create_postflight_marker "$PADDED_NUM" "$PROJECT_NAME" "$session_id" "skill-researcher" "research"
```

### Stage 3a: Read Artifact Number

Researcher uses "current" mode — it owns the sequence counter.

```bash
skill_read_artifact_number "$task_number" "$PADDED_NUM" "$PROJECT_NAME" "reports/" "current"
# Exports: ARTIFACT_NUMBER, ARTIFACT_PADDED
```

### Stage 4a: Clean Flag (Pass-Through)

Extract clean_flag for pass-through to subagent prompt. Do NOT run memory-retrieve.sh or cat ROADMAP.md here — delegate to subagent.

```bash
clean_flag="${clean_flag:-false}"
```

The subagent handles memory retrieval and roadmap consultation in its own context.

### Stage 4d: Collect Prior Implementation Context Paths

If task status is "implementing" or "partial", collect artifact paths (not content) to pass as @-references to the subagent:

```bash
prior_artifact_dir=""
if [ "$TASK_STATUS" = "implementing" ] || [ "$TASK_STATUS" = "partial" ]; then
    prior_artifact_dir="specs/${PADDED_NUM}_${PROJECT_NAME}"
fi
```

The subagent reads the relevant files using @-references in its own context.

### Stage 4: Prepare Delegation Context

Extract orchestrator_mode early (before delegation context JSON):

```bash
orchestrator_mode=$(echo "$delegation_context" | jq -r '.orchestrator_mode // "false"' 2>/dev/null || echo "false")
```

```json
{
  "session_id": "sess_{timestamp}_{random}",
  "delegation_depth": 1,
  "delegation_path": ["orchestrator", "research", "skill-researcher"],
  "timeout": 3600,
  "task_context": {
    "task_number": N,
    "task_name": "{PROJECT_NAME}",
    "description": "{DESCRIPTION}",
    "task_type": "{TASK_TYPE}"
  },
  "artifact_number": "{ARTIFACT_PADDED}",
  "focus_prompt": "{optional focus}",
  "effort_flag": "{effort_flag or null}",
  "model_flag": "{model_flag or null}",
  "orchestrator_mode": false,
  "roadmap_path": "specs/ROADMAP.md",
  "metadata_file_path": "specs/{NNN}_{SLUG}/.return-meta.json",
  "prior_artifact_dir": "{prior_artifact_dir or empty string}",
  "clean_flag": "{clean_flag}"
}
```

### Stage 5: Invoke Subagent

**CRITICAL**: Use the **Agent** tool (`subagent_type: "general-research-agent"`).

Build the prompt with these blocks in order:
1. Delegation context JSON
2. Task-specific instructions including:
   - "Follow the report format in @.claude/context/formats/report-format.md"
   - If `clean_flag` is not "true": "Run `bash .claude/scripts/memory-retrieve.sh '{DESCRIPTION}' '{TASK_TYPE}' '{focus_prompt}'` to retrieve relevant memories and incorporate them."
   - "If `specs/ROADMAP.md` exists, read @specs/ROADMAP.md for project context."
   - If `prior_artifact_dir` is non-empty: "If task status is implementing/partial, read recent artifacts from @{prior_artifact_dir}/summaries/, @{prior_artifact_dir}/handoffs/ (last 3), and @{prior_artifact_dir}/progress/ for context."

**DO NOT** use `Skill(general-research-agent)` — this will FAIL.

### Stage 5b: Self-Execution Fallback

If you performed work WITHOUT using the Agent tool, write `.return-meta.json` with status `"researched"` before proceeding to postflight. If you used the Agent tool, skip this stage.

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
skill_validate_artifact "$SUBAGENT_STATUS" "$ARTIFACT_PATH" "report"
```

### Stage 7: Update Task Status (Postflight)

```bash
# Step 1: Update status
skill_postflight_update "$task_number" "research" "$session_id" "$SUBAGENT_STATUS" "$orchestrator_mode"

# Step 2: Increment sequence counter (research only)
if [ "$SUBAGENT_STATUS" = "researched" ]; then
  skill_increment_artifact_number "$task_number"
fi

# Step 3: Write orchestrator handoff (only if orchestrator_mode=true)
skill_write_orchestrator_handoff "$orchestrator_mode" "$PADDED_NUM" "$PROJECT_NAME" \
  "research" "$SUBAGENT_STATUS" "$ARTIFACT_SUMMARY" "$ARTIFACT_PATH" "$ARTIFACT_TYPE" "plan"
```

### Stage 7a: Propagate Memory Candidates

```bash
skill_propagate_memory_candidates "$task_number" "$MEMORY_CANDIDATES"
```

### Stage 8: Link Artifacts

```bash
skill_link_artifacts "$task_number" "$ARTIFACT_PATH" "$ARTIFACT_TYPE" "$ARTIFACT_SUMMARY" '**Research**' '**Plan**'
```

### Stage 9: Cleanup

```bash
skill_cleanup "$PADDED_NUM" "$PROJECT_NAME"
```

### Stage 10: Return Brief Summary

Return a brief text summary (NOT JSON):
```
Research completed for task {N}:
- Created report at specs/{NNN}_{SLUG}/reports/MM_{short-slug}.md
- Status updated to [RESEARCHED]
```

---

## Error Handling

- **Task not found**: Exit immediately with error
- **Metadata missing**: Keep status "researching", do not cleanup marker, report error
- **Subagent timeout**: Return partial; keep status "researching" for resume

---

## MUST NOT (Context Protection)

Before delegating to the subagent, MUST NOT load file content into the lead context for passthrough. Specifically:

1. **MUST NOT `cat` format spec files** -- pass `@.claude/context/formats/report-format.md` reference to subagent instead
2. **MUST NOT run `memory-retrieve.sh`** -- instruct subagent to run it in its own context
3. **MUST NOT `cat` ROADMAP.md** -- pass `@specs/ROADMAP.md` reference to subagent instead
4. **MUST NOT read prior artifact file content** -- pass directory path as @-reference to subagent

**Context budget target**: Lead context growth above baseline should stay under ~500 tokens for preflight.

Reference: @.claude/context/patterns/context-protective-lead.md

---

## MUST NOT (Postflight Boundary)

After the agent returns, MUST NOT: edit source files, run build/test, use MCP/WebSearch, grep/analyze source, or write reports.

Postflight is LIMITED TO: reading metadata, calling update-task-status.sh, incrementing artifact_number, linking artifacts, cleanup.

Reference: @.claude/context/standards/postflight-tool-restrictions.md
