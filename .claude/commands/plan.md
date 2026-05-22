---
description: Create implementation plan for a task
allowed-tools: Skill, Agent, Bash(jq:*), Bash(git:*), Read, Edit
argument-hint: TASK_NUMBERS [--team [--team-size N]] [--fast|--hard] [--haiku|--sonnet|--opus]
model: opus
---

# /plan Command

Create a phased implementation plan for a task by delegating to the planner skill/subagent.

## Arguments

- `$1` - Task number(s) (required). Supports:
  - Single task: `352`
  - Comma-separated: `7, 22, 59`
  - Ranges: `22-24`
  - Combined: `7, 22-24, 59`
- Remaining args - Optional flags

When multiple task numbers are provided, the command enters multi-task mode (see STAGE 0 below). Single task numbers fall through to the existing single-task flow unchanged.

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

When `--team` is specified, planning is delegated to `skill-team-plan` which spawns multiple planning agents generating alternative plans in parallel. Each teammate produces a plan candidate, and the lead synthesizes findings into a final plan with trade-off analysis.

**Note**: Team mode requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable. If unavailable, gracefully degrades to single-agent planning.

## Anti-Bypass Constraint

**PROHIBITION**: You MUST NOT write plan artifacts directly using Write or Edit tools. All plan files MUST be created by invoking the appropriate skill (skill-planner or skill-team-plan) via the Skill tool.

**Why**: Direct writes bypass format enforcement (validate-artifact.sh), produce non-conforming artifacts missing required metadata fields and sections, and circumvent the delegation chain that ensures quality. A PostToolUse hook monitors all Write/Edit operations to artifact paths and will flag violations with corrective context.

**Required**: Always delegate to the Skill tool. Never write to `specs/*/plans/*.md` directly from this command.

## Execution

### STAGE 0: PARSE TASK NUMBERS

**Parse task arguments to separate task numbers from remaining args.**

```bash
source .claude/scripts/parse-command-args.sh "$ARGUMENTS"
# Exports: TASK_NUMBERS, REMAINING_ARGS, TEAM_MODE, TEAM_SIZE, EFFORT_FLAG, MODEL_FLAG,
#          CLEAN_FLAG, FORCE_FLAG, FOCUS_PROMPT
# Note: per-command team-size max clamp for plan (max 3):
[ "$TEAM_SIZE" -gt 3 ] && TEAM_SIZE=3
# Note: --roadmap flag is plan-specific; check REMAINING_ARGS for it:
[[ "$REMAINING_ARGS" =~ --roadmap ]] && roadmap_flag="true" || roadmap_flag="false"
```

**Dispatch decision**:

```
if len(TASK_NUMBERS) == 1:
    # SINGLE-TASK MODE
    task_number = TASK_NUMBERS[0]
    # Fall through to CHECKPOINT 1: GATE IN below

elif len(TASK_NUMBERS) > 1:
    # MULTI-TASK MODE
    # Continue to MULTI-TASK DISPATCH below
```

### MULTI-TASK DISPATCH

When `parse-command-args.sh` produces more than one task number in TASK_NUMBERS, execute the batch flow below instead of the single-task checkpoints.

#### Step 1: Batch Validation

Validate all tasks exist and are not in a terminal state:

```bash
validated_tasks=()
invalid_tasks=()

for task_num in "${task_numbers[@]}"; do
  task_data=$(jq -r --argjson num "$task_num" \
    '.active_projects[] | select(.project_number == $num)' \
    specs/state.json)

  if [ -z "$task_data" ]; then
    invalid_tasks+=("$task_num: not found")
    continue
  fi

  status=$(echo "$task_data" | jq -r '.status')

  # /plan accepts any non-terminal status
  if [ "$status" = "completed" ] || [ "$status" = "abandoned" ] || [ "$status" = "expanded" ]; then
    invalid_tasks+=("$task_num: terminal status [$status]")
  else
    validated_tasks+=("$task_num")
  fi
done

# Report invalid tasks but continue with valid ones
if [ ${#invalid_tasks[@]} -gt 0 ]; then
  echo "[WARN] Skipping invalid tasks:"
  for msg in "${invalid_tasks[@]}"; do
    echo "  - $msg"
  done
fi

if [ ${#validated_tasks[@]} -eq 0 ]; then
  echo "[FAIL] No valid tasks to process"
  exit 1
fi
```

#### Step 2: Generate Batch Session ID

```bash
batch_session_id="sess_$(date +%s)_$(od -An -N3 -tx1 /dev/urandom | tr -d ' ')"
```

#### Step 3: Dispatch Skills

For each validated task, invoke the appropriate planner skill using parallel Skill tool calls from the orchestrator's built-in batch loop:

1. Extract task_type per task from state.json
2. Route each task to the appropriate planner skill (extension routing or default `skill-planner`)
3. Invoke all skills in a single message (parallel execution, one skill per task)
4. Each skill runs the full single-task planning lifecycle independently (preflight, agent delegation, postflight)
5. Collect text results from all skills; read `.return-meta.json` in each task directory for structured data if needed

**Note**: Batch dispatch is handled directly by this command's orchestrator loop via parallel Skill tool calls, not by a separate batch skill.

#### Step 4: Batch Git Commit

After all skills return, produce a single git commit. Per-skill postflight may have already committed individual task changes; this batch commit captures any remaining unstaged changes and may be empty (which fails gracefully).

**Full success**:
```
plan tasks {range_summary}: create implementation plan

Tasks: {comma-separated list}
Session: {batch_session_id}
```

**Partial success**:
```
plan tasks {range_summary}: create implementation plan ({succeeded}/{total} succeeded)

Tasks completed: {comma-separated}
Tasks failed: {num} ({reason})[, {num} ({reason})]
Session: {batch_session_id}
```

#### Step 5: Consolidated Output

```markdown
## Batch Plan Results

Session: {batch_session_id}
Tasks requested: {count}
Succeeded: {count}
Failed: {count}
Skipped: {count}

### Succeeded

| Task | Title | Status | Artifact |
|------|-------|--------|----------|
| #7 | task_title | [PLANNED] | specs/007_slug/plans/01_short.md |
| #22 | task_title | [PLANNED] | specs/022_slug/plans/01_short.md |

### Failed

| Task | Error |
|------|-------|
| #23 | Invalid status [IMPLEMENTING] |

### Skipped

| Task | Reason |
|------|--------|
| #99 | Not found in state.json |

### Next Steps
- /implement 7, 22, 24, 59
```

**End of multi-task flow. Do NOT continue to the single-task checkpoints below.**

---

**The sections below handle SINGLE-TASK mode only (when `parse-command-args.sh` produces exactly one task number).**

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

**ABORT** if any validation fails.

**On GATE IN success**: Task validated. **IMMEDIATELY CONTINUE** to STAGE 2 below.

### STAGE 2: DELEGATE

**EXECUTE NOW**: After CHECKPOINT 1 completes, immediately invoke the Skill tool.

**Team Mode Routing** (when `--team` flag present):

If `TEAM_MODE == "true"`:
- Route to `skill-team-plan`
- Pass `TEAM_SIZE` parameter

**Extension Routing** (when `--team` flag NOT present):

Check extension manifests for task-type-specific plan routing:

```bash
# TASK_TYPE is exported by command-gate-in.sh

# Check extension routing for plan (skill_name starts empty)
skill_name=""
for manifest in .claude/extensions/*/manifest.json; do
  if [ -f "$manifest" ]; then
    ext_skill=$(jq -r --arg tt "$TASK_TYPE" \
      '.routing.plan[$tt] // empty' "$manifest")
    if [ -n "$ext_skill" ]; then
      skill_name="$ext_skill"
      break
    fi
  fi
done

# Fallback: if compound key (contains ":"), try base task_type
if [ -z "$skill_name" ] && echo "$TASK_TYPE" | grep -q ":"; then
  base_type=$(echo "$TASK_TYPE" | cut -d: -f1)
  for manifest in .claude/extensions/*/manifest.json; do
    if [ -f "$manifest" ]; then
      ext_skill=$(jq -r --arg tt "$base_type" \
        '.routing.plan[$tt] // empty' "$manifest")
      if [ -n "$ext_skill" ]; then
        skill_name="$ext_skill"
        break
      fi
    fi
  done
fi

# Fallback to default planner if no extension routing found
skill_name=${skill_name:-"skill-planner"}
```

**Extension-Based Routing Table**:

| Task Type | Skill to Invoke |
|-----------|-----------------|
| `founder` | `skill-founder-plan` (from founder extension) |
| `founder:deck` | `skill-deck-plan` (from founder extension) |
| `founder:{sub-type}` | Compound key lookup, falls back to `skill-founder-plan` |
| Other | `skill-planner` (default) |

**Skill Selection Logic**:
```
if TEAM_MODE == "true":
  skill_name = "skill-team-plan"
else:
  skill_name = {extension routing lookup} OR "skill-planner"
```

**Invoke the Skill tool NOW** with:
```
# For team mode:
skill: "skill-team-plan"
args: "task_number={N} research_path={path to research report if exists} prior_plan_path={path to prior plan if exists} team_size={TEAM_SIZE} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG} roadmap_flag={roadmap_flag}"

# For extension-routed skill (e.g., skill-founder-plan):
skill: "{skill_name from extension routing}"
args: "task_number={N} research_path={path to research report if exists} prior_plan_path={path to prior plan if exists} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG} roadmap_flag={roadmap_flag}"

# For default single-agent mode:
skill: "skill-planner"
args: "task_number={N} research_path={path to research report if exists} prior_plan_path={path to prior plan if exists} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG} roadmap_flag={roadmap_flag}"
```

If `MODEL_FLAG` is set, pass the `model` parameter to override the agent's default model:
- `MODEL_FLAG="haiku"` -> pass `model: haiku`
- `MODEL_FLAG="sonnet"` -> pass `model: sonnet`
- `MODEL_FLAG="opus"` -> pass `model: opus`
- `MODEL_FLAG=""` -> omit `model` parameter (use agent's frontmatter default: opus for planner/meta-builder/reviser; sonnet for general-purpose agents)

If `EFFORT_FLAG` is set, pass it as prompt context to the skill/agent for reasoning depth guidance.

The skill spawns agent(s) which analyze task requirements and research findings, decompose into logical phases, identify risks and mitigations, and create a plan in `specs/{NNN}_{SLUG}/plans/`.

**On DELEGATE success**: Plan created. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

```bash
bash .claude/scripts/command-gate-out.sh "$task_number" "plan" "$SESSION_ID"
# Reads .return-meta.json; applies defensive status correction if needed
# Runs validate-artifact.sh --fix (non-blocking)
```

1. **Verify state.json Status (Defensive)**

   **Only when skill reports success:**

   Check that state.json shows status "planned" for this task. If not, apply defensive correction:

   ```bash
   current_status=$(jq -r --argjson num "$task_number" \
     '.active_projects[] | select(.project_number == $num) | .status' \
     specs/state.json)

   if [ "$current_status" != "planned" ]; then
       echo "WARNING: state.json status is '$current_status', expected 'planned'. Applying defensive correction."
       bash .claude/scripts/update-task-status.sh postflight "$task_number" plan "$SESSION_ID"
   fi
   ```

2. **Verify TODO.md Status (Defensive)**

   **Only when skill reports success:**

   Check that the task entry in TODO.md shows `[PLANNED]`. If it still shows `[PLANNING]`, apply correction:

   ```bash
   if grep -q "- \*\*Status\*\*: \[PLANNING\]" <(grep -A 5 "^### ${task_number}\." specs/TODO.md); then
       echo "WARNING: TODO.md status not updated to [PLANNED]. Applying defensive correction."
   fi
   ```

   If the check finds a mismatch, use Edit tool to fix both:
   - Task entry: `- **Status**: [PLANNING]` -> `- **Status**: [PLANNED]`
   - Task Order: `**{N}** [PLANNING]` -> `**{N}** [PLANNED]`

3. **Verify Plan File Status (Defensive)**

   **Only when skill reports success:**

   Check that the plan file status marker shows `[NOT STARTED]` (expected state for a newly created plan). If it shows something unexpected like `[PLANNING]`, log a warning:

   ```bash
   # Find latest plan file
   plan_file=$(ls -1 "specs/${PADDED_NUM}_${PROJECT_NAME}/plans/"*.md 2>/dev/null | sort -V | tail -1)

   if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
       if grep -qE '^\*\*Status\*\*: \[PLANNING\]|^\- \*\*Status\*\*: \[PLANNING\]' "$plan_file"; then
           echo "WARNING: Plan file status still shows [PLANNING]. Expected [NOT STARTED] for newly created plan."
       fi
   fi
   ```

**RETRY** skill if validation fails.

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

Phases: {phase_count}
Estimated effort: {estimated_hours}

Status: [PLANNED]
Next: /implement {N}
```

## Error Handling

### GATE IN Failure
- Task not found: Return error with guidance
- Terminal status (completed/abandoned): Return error with current status

### DELEGATE Failure
- Skill fails: Keep [PLANNING], log error
- Timeout: Partial plan preserved, user can re-run

### GATE OUT Failure
- Missing artifacts: Log warning, continue with available
- Link failure: Non-blocking warning
