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

### Stage 4a: Memory Retrieval (Auto)

Skip if `clean_flag` is true.

```bash
memory_context=""
if [ "$clean_flag" != "true" ]; then
  memory_context=$(bash .claude/scripts/memory-retrieve.sh "$DESCRIPTION" "$TASK_TYPE" "$focus_prompt" 2>/dev/null) || memory_context=""
fi
```

### Stage 4c: Roadmap Consultation (Auto)

Skip if `clean_flag` is true.

```bash
roadmap_context=""
if [ "$clean_flag" != "true" ] && [ -f "specs/ROADMAP.md" ]; then
  roadmap_context=$(cat specs/ROADMAP.md)
fi
```

**Note**: If ROADMAP.md grows beyond ~100 lines, consider summarizing before injection.

### Stage 4d: Collect Prior Implementation Context

If task status is "implementing" or "partial", collect existing artifacts:

```bash
prior_implementation_context=""
if [ "$TASK_STATUS" = "implementing" ] || [ "$TASK_STATUS" = "partial" ]; then
    task_dir="specs/${PADDED_NUM}_${PROJECT_NAME}"
    for dir_type in summaries handoffs progress plans; do
        if [ -d "$task_dir/$dir_type" ]; then
            case "$dir_type" in
                summaries|plans) files=$(ls -1 "$task_dir/$dir_type/"*.md 2>/dev/null | sort -V) ;;
                handoffs)        files=$(ls -1 "$task_dir/$dir_type/"*.md 2>/dev/null | sort -V | tail -3) ;;
                progress)        files=$(ls -1 "$task_dir/$dir_type/"*.json 2>/dev/null | sort -V | tail -1) ;;
            esac
            for f in $files; do
                label=$(echo "$dir_type" | sed 's/s$//' | sed 's/\b./\u&/')
                prior_implementation_context+="\n\n## ${label}: $(basename "$f")\n\n$(cat "$f")"
            done
        fi
    done
    # Truncate if exceeds 500 lines
    if [ -n "$prior_implementation_context" ]; then
        line_count=$(echo -e "$prior_implementation_context" | wc -l)
        if [ "$line_count" -gt 500 ]; then
            prior_implementation_context=$(echo -e "$prior_implementation_context" | head -n 500)
            prior_implementation_context+="\n\n[NOTE: Prior implementation context truncated from $line_count lines to 500 lines budget]"
        fi
    fi
fi
```

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
  "prior_implementation_context": "{prior_implementation_context or empty string}"
}
```

### Stage 4b: Read and Inject Format Specification

```bash
format_content=$(cat .claude/context/formats/report-format.md)
```

### Stage 5: Invoke Subagent

**CRITICAL**: Use the **Agent** tool (`subagent_type: "general-research-agent"`).

Build the prompt with these blocks in order:
1. Delegation context JSON
2. `<artifact-format-specification>` block with `{format_content}` (Report Format Requirements)
3. `<prior-implementation-context>` block with `{prior_implementation_context}` (only if non-empty)
4. `{memory_context}` block (only if non-empty; already wrapped in `<memory-context>` tags)
5. `<roadmap-context>` block with `{roadmap_context}` (only if non-empty)
6. Task-specific instructions

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
skill_postflight_update "$task_number" "research" "$session_id" "$SUBAGENT_STATUS"

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

## MUST NOT (Postflight Boundary)

After the agent returns, MUST NOT: edit source files, run build/test, use MCP/WebSearch, grep/analyze source, or write reports.

Postflight is LIMITED TO: reading metadata, calling update-task-status.sh, incrementing artifact_number, linking artifacts, cleanup.

Reference: @.claude/context/standards/postflight-tool-restrictions.md
