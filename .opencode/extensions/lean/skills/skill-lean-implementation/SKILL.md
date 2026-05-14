---
name: skill-lean-implementation
description: Implement Lean 4 proofs and definitions using lean-lsp tools. Invoke for Lean-language implementation tasks.
allowed-tools: Task, Bash, Edit, Read, Write
---

# Lean Implementation Skill

Thin wrapper that delegates Lean 4 proof implementation to `lean-implementation-agent` subagent.

**IMPORTANT**: This skill implements the skill-internal postflight pattern. After the subagent returns,
this skill handles all postflight operations (status update, artifact linking, git commit) before returning.

## Trigger Conditions

This skill activates when:
- Task type is "lean4" or "lean" (either accepted)
- /implement command targets a Lean task
- Plan exists and task is ready for implementation

---

## Execution Flow

### Stage 1: Input Validation

Validate required inputs:
- `task_number` - Must be provided and exist in state.json
- Task status must allow implementation (planned, implementing, partial)
- Task type must be "lean" or "lean4"

```bash
# Lookup task
task_data=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num)' \
  specs/state.json)

# Validate exists
if [ -z "$task_data" ]; then
  return error "Task $task_number not found"
fi

# Extract fields
task_type=$(echo "$task_data" | jq -r '.task_type // "general"')
status=$(echo "$task_data" | jq -r '.status')
project_name=$(echo "$task_data" | jq -r '.project_name')

# Validate task_type (accept both "lean" and "lean4")
if [ "$task_type" != "lean" ] && [ "$task_type" != "lean4" ]; then
  return error "Task $task_number is not a Lean task (task_type: $task_type)"
fi
```

#### Task Complexity Warning (GATE IN)

After identifying the plan file, extract the estimated effort and warn if total exceeds 20 hours:

```bash
plan_file="specs/${padded_num}_${project_name}/plans/$(ls specs/${padded_num}_${project_name}/plans/ 2>/dev/null | tail -1)"
if [ -f "$plan_file" ]; then
    effort_line=$(grep -i "Effort\|estimate\|hours\?" "$plan_file" 2>/dev/null | head -5)
    effort_hours=$(echo "$effort_line" | grep -oP '\d+(?=\s*h(our)?s?)' | head -1)
    if [ -n "$effort_hours" ] && [ "$effort_hours" -gt 20 ] 2>/dev/null; then
        echo "WARNING: Task complexity exceeds 20 hours estimated effort (${effort_hours}h)."
        echo "  Consider using /team-implement or breaking into smaller phases."
        echo "  Proceeding with single-agent implementation."
    fi
fi
```

This warning is non-blocking. If effort hours cannot be parsed, no warning is emitted.

---

### Stage 2: Preflight Status Update

Update task status to "implementing" BEFORE invoking subagent.

**Update state.json**:
```bash
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   --arg status "implementing" \
   --arg sid "$session_id" \
  '(.active_projects[] | select(.project_number == '$task_number')) |= . + {
    status: $status,
    last_updated: $ts,
    session_id: $sid,
    started: $ts
  }' specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
```

**Update TODO.md**: Use Edit tool to change status marker from `[PLANNED]` to `[IMPLEMENTING]`.

---

### Stage 3: Prepare Delegation Context

Prepare delegation context for the subagent:

```json
{
  "session_id": "sess_{timestamp}_{random}",
  "delegation_depth": 1,
  "delegation_path": ["orchestrator", "implement", "skill-lean-implementation"],
  "timeout": 7200,
  "task_context": {
    "task_number": N,
    "task_name": "{project_name}",
    "description": "{description}",
    "task_type": "${task_type}"
  },
  "plan_path": "specs/{N}_{SLUG}/plans/implementation-{NNN}.md",
  "metadata_file_path": "specs/{N}_{SLUG}/.return-meta.json"
}
```

---

### Stage 4: Invoke Subagent

**CRITICAL**: You MUST use the **Task** tool to spawn the subagent.

**Required Tool Invocation**:
```
Tool: Task (NOT Skill)
Parameters:
  - subagent_type: "lean-implementation-agent"
  - prompt: [Include task_context, delegation_context, plan_path, metadata_file_path]
  - description: "Execute Lean implementation for task {N}"
```

**DO NOT** use `Skill(lean-implementation-agent)` - this will FAIL.

The subagent will:
- Load implementation context files (MCP tools guide, tactic patterns)
- Parse plan and find resume point
- Execute phases sequentially using lean-lsp MCP tools
- Verify proofs with `lean_goal` and `lake build`
- Create implementation summary
- Write metadata to `specs/{N}_{SLUG}/.return-meta.json`
- Return a brief text summary (NOT JSON)

---

### Stage 5: Parse Subagent Return (Read Metadata File)

After subagent returns, read the metadata file:

```bash
metadata_file="specs/${padded_num}_${project_name}/.return-meta.json"

if [ -f "$metadata_file" ] && jq empty "$metadata_file" 2>/dev/null; then
    status=$(jq -r '.status' "$metadata_file")
    artifact_path=$(jq -r '.artifacts[0].path // ""' "$metadata_file")
    phases_completed=$(jq -r '.metadata.phases_completed // 0' "$metadata_file")
    phases_total=$(jq -r '.metadata.phases_total // 0' "$metadata_file")
else
    echo "Error: Invalid or missing metadata file"
    status="failed"
fi
```

---

### Stage 6: Zero-Debt Verification Gate (MANDATORY)

**CRITICAL**: Before proceeding to status update, verify the zero-debt completion gate.

If status from metadata is "implemented":

```bash
# Check for sorries in modified files
sorry_count=$(grep -r "\bsorry\b" Theories/ 2>/dev/null | grep -v "^[[:space:]]*--" | wc -l)

# Check for vacuous definitions (semantically equivalent to sorry)
vacuous_count=$(grep -rn "^\s*\(noncomputable \)\?\(def\|theorem\|lemma\|instance\).*:= \(True\|Unit\|trivial\|Trivial\)\s*$" Theories/ 2>/dev/null | wc -l)
if [ "$vacuous_count" -gt 0 ]; then
    echo "  vacuous_count=$vacuous_count (def/theorem/lemma/instance := True|Unit|trivial|Trivial)"
fi

# Verify build passes
if ! lake build 2>/dev/null; then
    build_failed=true
fi

if [ "$sorry_count" -gt 0 ] || [ "$vacuous_count" -gt 0 ] || [ "$build_failed" = true ]; then
    echo "Zero-debt gate FAILED"
    status="partial"
fi
```

---

### Stage 6b: Plan Compliance Spot-Check (MANDATORY)

After the Zero-Debt gate passes, verify that plan-declared deliverables exist and that no replacement function delegates to the function it purports to replace.

**This stage only runs if status from metadata is "implemented".** If the agent returned "partial" or "failed", skip Stage 6b and proceed to Stage 7.

**Step 1: Extract plan goal names**

```bash
# plan_file is available from Stage 1 (GATE IN complexity warning)
if [ ! -f "$plan_file" ]; then
    echo "WARNING: Plan file not found — skipping compliance check"
    compliance_check="skipped"
else
    # Extract backtick-wrapped identifiers from **Goals**: section
    goal_names=$(sed -n '/^\*\*Goals\*\*:/,/^\*\*[^G]/p' "$plan_file" \
      | grep -oP '`[a-zA-Z_][a-zA-Z0-9_'"'"']*`' \
      | tr -d '`' | sort -u)

    if [ -z "$goal_names" ]; then
        echo "INFO: No goal names found in plan **Goals**: section — skipping compliance check"
        compliance_check="skipped"
    else
        compliance_failed=false

        # Step 2: Deliverable existence check
        for name in $goal_names; do
            if grep -rq "^\(noncomputable \)\?\(theorem\|def\|lemma\|instance\) $name\b" Theories/ 2>/dev/null; then
                echo "  [OK] $name — found in Theories/"
            else
                echo "  [MISSING] $name — not found in Theories/ (plan deliverable absent)"
                compliance_failed=true
            fi
        done

        # Step 3: Delivery integrity check
        replacement_targets=$(grep -oP '(?:replacement for|replaces|bypasses|supersedes)\s+`[a-zA-Z_][a-zA-Z0-9_'"'"']*`' "$plan_file" 2>/dev/null \
            | grep -oP '`[a-zA-Z_][a-zA-Z0-9_'"'"']*`' | tr -d '`')

        for replaced in $replacement_targets; do
            for new_name in $goal_names; do
                new_file=$(grep -rl "^\(noncomputable \)\?\(theorem\|def\|lemma\|instance\) $new_name\b" Theories/ 2>/dev/null | head -1)
                if [ -n "$new_file" ] && grep -q "\b${replaced}\b" "$new_file"; then
                    echo "  [INTEGRITY FAIL] $new_name references $replaced in $new_file"
                    echo "    Plan declared $new_name as replacement for $replaced, but implementation delegates to it."
                    compliance_failed=true
                fi
            done
        done

        if [ "$compliance_failed" = true ]; then
            echo "Plan compliance spot-check FAILED"
            compliance_check="failed"
            status="partial"
        else
            echo "Plan compliance spot-check PASSED"
            compliance_check="passed"
        fi
    fi
fi
```

**Step 4: Record compliance result in metadata**

The `compliance_check` value ("passed", "failed", or "skipped") must be included in the `.return-meta.json` update passed to the GATE OUT stage. Update the metadata read logic to propagate this field.

---

### Stage 7: Update Task Status (Postflight)

**If status is "implemented"** (verified by Stage 6):

Update state.json to "completed":
```bash
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   --arg status "completed" \
  '(.active_projects[] | select(.project_number == '$task_number')) |= . + {
    status: $status,
    last_updated: $ts,
    completed: $ts
  }' specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
```

Update TODO.md: Change status marker from `[IMPLEMENTING]` to `[COMPLETED]`.

**If status is "partial"**:

Keep status as "implementing" but update resume point.
TODO.md stays as `[IMPLEMENTING]`.

---

### Stage 8: Link Artifacts

Add summary artifact to state.json.

```bash
if [ -n "$summary_artifact_path" ]; then
    jq --arg path "$summary_artifact_path" \
       --arg summary "$summary_artifact_summary" \
      '(.active_projects[] | select(.project_number == '$task_number')).artifacts += [{"path": $path, "type": "summary", "summary": $summary}]' \
      specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
fi
```

---

### Stage 9: Git Commit

Commit changes with session ID. If the subagent already created per-phase commits (Phase Checkpoint Protocol), skip the batch commit to avoid redundant history:

```bash
# Check if per-phase commits already exist from subagent Phase Checkpoint Protocol
if git log --oneline -10 | grep -q "phase [0-9]\+:"; then
    echo "Per-phase commits detected — skipping batch commit."
    echo "Phase commits already capture implementation history."
else
    # No per-phase commits found — create a batch commit
    git add \
      "Theories/" \
      "specs/${padded_num}_${project_name}/summaries/" \
      "specs/${padded_num}_${project_name}/plans/" \
      "specs/TODO.md" \
      "specs/state.json"
    git commit -m "task ${task_number}: complete implementation

Session: ${session_id}
"
fi

# Always commit state updates if not already staged
git add "specs/TODO.md" "specs/state.json" 2>/dev/null || true
git diff --cached --quiet || git commit -m "task ${task_number}: update task state

Session: ${session_id}
"
```

---

### Stage 10: Return Brief Summary

Return a brief text summary (NOT JSON). Example:

```
Lean implementation completed for task {N}:
- All {phases_total} phases executed, all proofs verified
- Lake build: Success
- Key theorems: {theorem names}
- Created summary at specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md
- Status updated to [COMPLETED]
- Changes committed
```

---

## Error Handling

### Input Validation Errors
Return immediately with error message if task not found, wrong language, or status invalid.

### Metadata File Missing
If subagent didn't write metadata file:
1. Keep status as "implementing"
2. Report error to user

### Git Commit Failure
Non-blocking: Log failure but continue with success response.

### Subagent Timeout
Return partial status if subagent times out (default 7200s).
Keep status as "implementing" for resume.

---

## Return Format

This skill returns a **brief text summary** (NOT JSON). The JSON metadata is written to the file and processed internally.
