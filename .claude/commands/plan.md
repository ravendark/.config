---
description: Create implementation plan for a task
allowed-tools: Skill, Agent, Bash(jq:*), Bash(git:*), Read, Edit
argument-hint: TASK_NUMBERS [--team [--team-size N]] [--fast|--hard] [--haiku|--sonnet|--opus]
model: opus
---

# /plan Command

Create a phased implementation plan for a task by delegating to the planner skill/subagent.

## Arguments

- `$1` - Task number(s): single (`352`), comma-separated (`7, 22, 59`), ranges (`22-24`), or combined
- Remaining args - Optional flags

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--team` | Enable multi-agent parallel planning with multiple teammates | false |
| `--team-size N` | Number of planning teammates to spawn (2-3) | 2 |
| `--fast` | Low-effort mode: lighter reasoning, faster responses | false |
| `--hard` | High-effort mode: deeper reasoning, more thorough analysis | false |
| `--haiku` | Use Haiku model (fastest, lowest cost) | false |
| `--sonnet` | Use Sonnet model (balanced cost/quality) | false |
| `--opus` | Use Opus model (highest quality, same as agent default) | false |
| `--clean` | Skip automatic memory retrieval | false |
| `--roadmap` | Include ROADMAP.md review/update phases in plan | false |

## Anti-Bypass Constraint

**PROHIBITION**: You MUST NOT write plan artifacts directly using Write or Edit tools. All plan files MUST be created by invoking the appropriate skill (skill-planner or skill-team-plan) via the Skill tool.

**Required**: Always delegate to the Skill tool. Never write to `specs/*/plans/*.md` directly from this command.

## Execution

### STAGE 0: PARSE TASK NUMBERS

```bash
source .claude/scripts/parse-command-args.sh "$ARGUMENTS"
# Exports: TASK_NUMBERS, REMAINING_ARGS, TEAM_MODE, TEAM_SIZE, EFFORT_FLAG, MODEL_FLAG,
#          CLEAN_FLAG, FORCE_FLAG, FOCUS_PROMPT
[ "$TEAM_SIZE" -gt 3 ] && TEAM_SIZE=3
[[ "$REMAINING_ARGS" =~ --roadmap ]] && roadmap_flag="true" || roadmap_flag="false"
```

If `len(TASK_NUMBERS) > 1`: continue to MULTI-TASK DISPATCH below.
If `len(TASK_NUMBERS) == 1`: fall through to CHECKPOINT 1: GATE IN.

---

### MULTI-TASK DISPATCH

#### Step 1: Batch Validation

```bash
validated_tasks=(); invalid_tasks=()
for task_num in "${task_numbers[@]}"; do
  task_data=$(jq -r --argjson num "$task_num" '.active_projects[] | select(.project_number == $num)' specs/state.json)
  if [ -z "$task_data" ]; then invalid_tasks+=("$task_num: not found"); continue; fi
  status=$(echo "$task_data" | jq -r '.status')
  if [ "$status" = "completed" ] || [ "$status" = "abandoned" ] || [ "$status" = "expanded" ]; then
    invalid_tasks+=("$task_num: terminal status [$status]")
  else
    validated_tasks+=("$task_num")
  fi
done
# Report invalid tasks; if no validated tasks remain, ABORT
```

#### Step 2: Generate Batch Session ID

```bash
batch_session_id="sess_$(date +%s)_$(od -An -N3 -tx1 /dev/urandom | tr -d ' ')"
```

#### Step 3: Dispatch Skills

For each validated task, invoke the appropriate planner skill using parallel Skill tool calls:
- Extract task_type per task from state.json; route using extension manifests or default `skill-planner`
- If `--team`: use `skill-team-plan`; invoke all skills in a single message (parallel execution)
- Collect results; read `.return-meta.json` for structured data

#### Step 4: Batch Git Commit and Consolidated Output

Git commit remaining changes (non-blocking), then display batch results table with session ID, counts (requested/succeeded/failed/skipped), and per-task status. Suggest `/implement {succeeded_task_numbers}` as next step.

**End of multi-task flow. Do NOT continue to the single-task checkpoints below.**

---

### CHECKPOINT 1: GATE IN

```bash
source .claude/scripts/command-gate-in.sh "$task_number" "plan"
# Exports: SESSION_ID, TASK_TYPE, TASK_STATUS, PROJECT_NAME, DESCRIPTION, PADDED_NUM
# Displays: [PLAN] Task {N}: {project_name}
# Aborts if task not found or in terminal status
```

**Load Context** (plan-specific):
- Task description from DESCRIPTION (exported by gate-in)
- Research reports from `specs/${PADDED_NUM}_${PROJECT_NAME}/reports/` (if any)
- Discover prior plan (if any):
  ```bash
  prior_plan_path=$(ls -1 "specs/${PADDED_NUM}_${PROJECT_NAME}/plans/"*.md 2>/dev/null | sort -V | tail -1)
  ```

**On GATE IN success**: Task validated. **IMMEDIATELY CONTINUE** to STAGE 2 below.

### STAGE 2: DELEGATE

**EXECUTE NOW**: After CHECKPOINT 1 completes, immediately invoke the Skill tool.

**Team Mode Routing** (when `--team` flag present): Route to `skill-team-plan`.

**Extension Routing** (when `--team` flag NOT present):

```bash
source .claude/scripts/command-route-skill.sh "plan" "$TASK_TYPE" "skill-planner"
skill_name="$SKILL_NAME"
# Defensive correction (state.json + TODO.md) handled by command-gate-out.sh
```

**Routing table**:

| Task Type | Skill to Invoke |
|-----------|-----------------|
| `neovim`, `nix` | `skill-planner` (default; extensions override only if configured) |
| `general`, `meta`, `markdown` | `skill-planner` (default) |
| Extension type | Resolved via extension manifest routing |

**Invoke the Skill tool NOW** with:
```
# For team mode:
skill: "skill-team-plan"
args: "task_number={N} research_path={path if exists} prior_plan_path={prior_plan_path} team_size={TEAM_SIZE} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG} roadmap_flag={roadmap_flag} orchestrator_mode=false"

# For single-agent mode:
skill: "{skill_name}"
args: "task_number={N} research_path={path if exists} prior_plan_path={prior_plan_path} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG} roadmap_flag={roadmap_flag} orchestrator_mode=false"
```

Pass `model` parameter if `MODEL_FLAG` is set. Pass `effort_flag` as prompt context if set.

**On DELEGATE success**: Plan created. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

```bash
bash .claude/scripts/command-gate-out.sh "$task_number" "plan" "$SESSION_ID"
# Reads .return-meta.json; applies defensive status correction if needed
# Runs validate-artifact.sh --fix (non-blocking)
# Defensive correction (state.json + TODO.md) handled by this script
```

**Verify Plan File Status (Defensive)** (plan-specific):

Only when skill reports success: Check that the plan file metadata shows `[NOT STARTED]` (expected state for a newly created plan):

```bash
plan_file=$(ls -1 "specs/${PADDED_NUM}_${PROJECT_NAME}/plans/"*.md 2>/dev/null | sort -V | tail -1)
if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
    if grep -qE '^\*\*Status\*\*: \[PLANNING\]|^\- \*\*Status\*\*: \[PLANNING\]' "$plan_file"; then
        echo "WARNING: Plan file status still shows [PLANNING]. Expected [NOT STARTED] for newly created plan."
    fi
fi
```

**On GATE OUT success**: Plan verified. **IMMEDIATELY CONTINUE** to CHECKPOINT 3 below.

### CHECKPOINT 3: COMMIT

```bash
git add -A
git commit -m "$(cat <<'EOF'
task {N}: create implementation plan

Session: {SESSION_ID}

EOF
)"
```

Commit failure is non-blocking (log and continue).

## Output

```
Plan created for Task #{N}
Plan: specs/{NNN}_{SLUG}/plans/MM_{short-slug}.md
Phases: {phase_count} | Estimated effort: {estimated_hours}
Status: [PLANNED] | Next: /implement {N}
```

## Error Handling

- **GATE IN Failure**: Task not found or terminal status — return error with guidance
- **DELEGATE Failure**: Keep [PLANNING], log error; timeout preserves partial progress for re-run
- **GATE OUT Failure**: Missing artifacts — log warning, continue with available
