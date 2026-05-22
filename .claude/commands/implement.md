---
description: Execute implementation with resume support
allowed-tools: Skill, Agent, Bash(jq:*), Bash(git:*), Read, Edit, Glob
argument-hint: TASK_NUMBERS [--team [--team-size N]] [--force] [--fast|--hard] [--haiku|--sonnet|--opus]
model: opus
---

# /implement Command

Execute implementation plan with automatic resume support by delegating to the appropriate implementation skill/subagent.

## Arguments

- `$1` - Task number(s) (required). Supports:
  - Single task: `353`
  - Comma-separated: `7, 22, 59`
  - Ranges: `22-24`
  - Combined: `7, 22-24, 59`
- Optional: `--force` to override status validation

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--team` | Enable parallel phase execution with multiple teammates | false |
| `--team-size N` | Number of implementation teammates to spawn (2-4) | 2 |
| `--force` | Override status validation | false |
| `--fast` | Low-effort mode: lighter reasoning, faster responses | false |
| `--hard` | High-effort mode: deeper reasoning, more thorough analysis | false |
| `--haiku` | Use Haiku model (fastest, lowest cost) | false |
| `--sonnet` | Use Sonnet model (balanced cost/quality) | false |
| `--opus` | Use Opus model (highest quality, same as agent default) | false |
| `--clean` | Skip automatic memory retrieval | false |

When `--team` is specified, implementation is delegated to `skill-team-implement` which spawns teammates to execute independent phases in parallel. Dependent phases wait for their dependencies. A debugger teammate can be spawned on build errors.

**Note**: Team mode requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable. If unavailable, gracefully degrades to single-agent implementation.

## Anti-Bypass Constraint

**PROHIBITION**: You MUST NOT write implementation summary artifacts directly using Write or Edit tools. All summary files MUST be created by invoking the appropriate skill (skill-implementer or skill-team-implement) via the Skill tool.

**Why**: Direct writes bypass format enforcement (validate-artifact.sh), produce non-conforming artifacts missing required metadata fields and sections, and circumvent the delegation chain that ensures quality. A PostToolUse hook monitors all Write/Edit operations to artifact paths and will flag violations with corrective context.

**Required**: Always delegate to the Skill tool. Never write to `specs/*/summaries/*.md` directly from this command.

## Execution

**Note**: Delegate to skills for task-type-specific implementation.

### STAGE 0: PARSE TASK NUMBERS

Parse raw arguments to extract task numbers and remaining arguments (flags, focus prompts).

```bash
source .claude/scripts/parse-command-args.sh "$ARGUMENTS"
# Exports: TASK_NUMBERS, REMAINING_ARGS, TEAM_MODE, TEAM_SIZE, EFFORT_FLAG, MODEL_FLAG,
#          CLEAN_FLAG, FORCE_FLAG, FOCUS_PROMPT
# Note: per-command team-size max clamp for implement (max 4):
[ "$TEAM_SIZE" -gt 4 ] && TEAM_SIZE=4
```

**Examples**:

| Input | TASK_NUMBERS | REMAINING_ARGS | Mode |
|-------|-------------|----------------|------|
| `7` | `7` | `` | single |
| `7, 22-24, 59` | `7 22 23 24 59` | `` | multi |
| `7 --force` | `7` | `--force` | single |
| `7, 22-24 --team` | `7 22 23 24` | `--team` | multi |
| `10-12, 15 --force` | `10 11 12 15` | `--force` | multi |

**Dispatch Decision**:

```
if len(TASK_NUMBERS) == 1:
    # SINGLE-TASK MODE
    task_number = TASK_NUMBERS[0]
    # Fall through to CHECKPOINT 1: GATE IN below (existing flow, unchanged)

elif len(TASK_NUMBERS) > 1:
    # MULTI-TASK MODE
    # Continue to MULTI-TASK DISPATCH below
```

**Single-task fallthrough**: When exactly one task number is parsed (including degenerate ranges like `7-7` or `7,7,7` that deduplicate to `[7]`), execution continues directly to CHECKPOINT 1: GATE IN. The entire existing single-task flow is unchanged.

---

### MULTI-TASK DISPATCH

When `parse-command-args.sh` produces more than one task number in TASK_NUMBERS, enter multi-task mode. This section replaces the single-task checkpoints for the batch operation.

#### Step 1: Batch Validation

Validate all tasks exist and have valid status before spawning any agents.

```bash
validated_tasks=()
skipped_tasks=()

for task_num in "${task_numbers[@]}"; do
  task_data=$(jq -r --argjson num "$task_num" \
    '.active_projects[] | select(.project_number == $num)' \
    specs/state.json)

  if [ -z "$task_data" ]; then
    skipped_tasks+=("$task_num: not found")
    continue
  fi

  status=$(echo "$task_data" | jq -r '.status')

  # Block terminal statuses only; --force overrides completed
  case "$status" in
    completed)
      if [ "$FORCE_FLAG" = "true" ]; then
        : # Allow with --force
      else
        skipped_tasks+=("$task_num: already completed (use --force)")
        continue
      fi
      ;;
    abandoned|expanded)
      skipped_tasks+=("$task_num: terminal status [$status]")
      continue
      ;;
  esac

  validated_tasks+=("$task_num")
done
```

**Report skipped tasks** (warnings, non-blocking):
```
if skipped_tasks is not empty:
    [WARN] Skipping tasks:
      - {task_num}: {reason}
      ...

if validated_tasks is empty:
    [FAIL] No valid tasks to implement
    ABORT
```

#### Step 2: Generate Batch Session ID

```bash
batch_session_id="sess_$(date +%s)_$(od -An -N3 -tx1 /dev/urandom | tr -d ' ')"
```

#### Step 3: Dispatch Skills

For each validated task, invoke the appropriate implementation skill using parallel Skill tool calls from the orchestrator's built-in batch loop:

- Extract task type per task (from state.json)
- Route per task using existing task-type-based routing from extension manifests (or default `skill-implementer`)
- Invoke all skills in a single message (parallel execution, one skill per task)
- Each skill runs the full single-task implementation lifecycle independently (preflight, agent delegation, postflight)
- Collect text results from all skills; read `.return-meta.json` in each task directory for structured data if needed

**Note**: Batch dispatch is handled directly by this command's orchestrator loop via parallel Skill tool calls, not by a separate batch skill.

**--force flag**: When `FORCE_FLAG == "true"`, it is passed to each invoked skill, which passes it through to its agent to bypass status validation in single-task GATE IN.

**--team flag**: When `TEAM_MODE == "true"`, each task routes to `skill-team-implement` (multiple agents per task). Total agents = `N_tasks * TEAM_SIZE`. Cost warning applies.

#### Step 4: Batch Git Commit

After all skills return results, produce a single git commit. Per-skill postflight may have already committed individual task changes; this batch commit captures any remaining unstaged changes and may be empty (which fails gracefully).

**Full success**:
```bash
git add -A
git commit -m "$(cat <<'EOF'
implement tasks {range_summary}: complete implementation

Tasks: {comma-separated list}
Session: {batch_session_id}

EOF
)"
```

**Partial success**:
```bash
git add -A
git commit -m "$(cat <<'EOF'
implement tasks {range_summary}: complete implementation ({succeeded}/{total} succeeded)

Tasks completed: {comma-separated}
Tasks failed: {num} ({reason})[, {num} ({reason})]
Session: {batch_session_id}

EOF
)"
```

Commit failure is non-blocking (log and continue).

#### Step 5: Consolidated Output

Display results after all agents complete.

```markdown
## Batch Implement Results

Session: {batch_session_id}
Tasks requested: {count}
Succeeded: {count}
Failed: {count}
Skipped: {count}

### Succeeded

| Task | Title | Status | Artifact |
|------|-------|--------|----------|
| #7 | project_name | [COMPLETED] | specs/007_slug/summaries/01_short-summary.md |
| #22 | project_name | [COMPLETED] | specs/022_slug/summaries/01_short-summary.md |

### Failed

| Task | Error |
|------|-------|
| #23 | Agent timeout |

### Skipped

| Task | Reason |
|------|--------|
| #99 | Not found in state.json |

### Next Steps
- Re-run failed tasks individually: /implement {N}
```

**After consolidated output, STOP.** The multi-task flow does not continue to CHECKPOINT 1.

---

### CHECKPOINT 1: GATE IN

```bash
source .claude/scripts/command-gate-in.sh "$task_number" "implement"
# Exports: SESSION_ID, TASK_TYPE, TASK_STATUS, PROJECT_NAME, DESCRIPTION, PADDED_NUM
# Displays: [IMPLEMENT] Task {N}: {project_name}
# Aborts if task not found or in terminal status (unless --force)
```

**--force override** (implement-specific): If `FORCE_FLAG == "true"` and gate-in rejects due to terminal status, override the rejection:
```bash
# If TASK_STATUS is "completed" and FORCE_FLAG is "true", proceed anyway
# (gate-in aborts on completed; --force caller must handle this override inline)
```

**Load Implementation Plan** (implement-specific):
Find latest: `specs/${PADDED_NUM}_${PROJECT_NAME}/plans/*.md` (sorted by version)

If no plan: ABORT "No implementation plan found. Run /plan {N} first."

**Detect Resume Point** (implement-specific):
Scan plan for phase status markers:
- [NOT STARTED] → Start here
- [IN PROGRESS] → Resume here
- [COMPLETED] → Skip
- [PARTIAL] → Resume here

If all [COMPLETED]: Task already done

**ABORT** if any validation fails.

**On GATE IN success**: Task validated. **IMMEDIATELY CONTINUE** to STAGE 2 below.

### STAGE 2: DELEGATE

**EXECUTE NOW**: After CHECKPOINT 1 completes, immediately invoke the Skill tool.

**Team Mode Routing** (when `--team` flag present):

If `TEAM_MODE == "true"`:
- Route to `skill-team-implement`
- Pass `TEAM_SIZE` parameter

**Extension Routing** (when `--team` flag NOT present):

Check extension manifests for task-type-specific implement routing:

```bash
# TASK_TYPE is exported by command-gate-in.sh

# Check extension routing for implement (skill_name starts empty)
skill_name=""
for manifest in .claude/extensions/*/manifest.json; do
  if [ -f "$manifest" ]; then
    ext_skill=$(jq -r --arg tt "$TASK_TYPE" \
      '.routing.implement[$tt] // empty' "$manifest")
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
        '.routing.implement[$tt] // empty' "$manifest")
      if [ -n "$ext_skill" ]; then
        skill_name="$ext_skill"
        break
      fi
    fi
  done
fi

# Fallback to default implementer if no extension routing found
skill_name=${skill_name:-"skill-implementer"}
```

**Extension-Based Routing Table**:

| Language | Skill to Invoke |
|----------|-----------------|
| `founder` | `skill-founder-implement` (from founder extension) |
| `founder:deck` | `skill-deck-implement` (from founder extension) |
| `founder:{sub-type}` | Compound key lookup, falls back to `skill-founder-implement` |
| `general`, `meta`, `markdown` | `skill-implementer` (default) |
| `formal`, `logic`, `math`, `physics` | `skill-implementer` (default) |

**Extension Skills Location**: Extension skills are located in `.claude/extensions/{ext}/skills/`. Claude Code discovers these skills via extension manifest `routing.implement` entries.

**Skill Selection Logic**:
```
if TEAM_MODE == "true":
  skill_name = "skill-team-implement"
else:
  skill_name = {extension routing lookup} OR "skill-implementer"
```

**Invoke the Skill tool NOW** with:
```
# For team mode:
skill: "skill-team-implement"
args: "task_number={N} plan_path={path to implementation plan} resume_phase={phase number} team_size={TEAM_SIZE} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG}"

# For extension-routed skill (e.g., skill-founder-implement):
skill: "{skill_name from extension routing}"
args: "task_number={N} plan_path={path to implementation plan} resume_phase={phase number} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG}"

# For default single-agent mode:
skill: "skill-implementer"
args: "task_number={N} plan_path={path to implementation plan} resume_phase={phase number} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG}"
```

If `MODEL_FLAG` is set, pass the `model` parameter to override the agent's default model.
If `EFFORT_FLAG` is set, pass it as prompt context to the skill/agent for reasoning depth guidance.

The skill will spawn the appropriate agent(s) which execute plan phases (in parallel for team mode), update phase markers, create commits per phase, and return a structured result.

**On DELEGATE success**: Implementation complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

```bash
bash .claude/scripts/command-gate-out.sh "$task_number" "implement" "$SESSION_ID"
# Reads .return-meta.json; applies defensive status correction if needed
# Runs validate-artifact.sh --fix (non-blocking)
```

1. **Validate Return**
   Required fields: status, summary, artifacts, metadata (phases_completed, phases_total)

2. **Verify Artifacts**
   Check summary file exists on disk (if implemented)

3. **Verify Status Updated**
   The skill handles status updates internally (preflight and postflight).

   **If result.status == "implemented":**
   Confirm status is now "completed" in state.json.

   **If result.status == "partial":**
   Confirm status is still "implementing", resume point noted.

4. **Populate Completion Summary (if implemented)** (implement-specific)

   **Only when result.status == "implemented":**

   Extract the summary from the skill result and update state.json:
   ```bash
   # Get completion summary from skill result (result.summary field)
   completion_summary="$result_summary"

   # Update state.json with completion_summary field
    jq --arg num "$task_number" \
       --arg summary "$completion_summary" \
       '(.active_projects[] | select(.project_number == ($num | tonumber))) += {
         completion_summary: $summary
       }' specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
   ```

   **Update TODO.md with Summary line:**
   Add a `- **Summary**: {completion_summary}` line to the task entry in TODO.md, after the Completed date line.

   **Skip if result.status == "partial":**
   Partial implementations do not get completion summaries.

5. **Verify Plan File Status Updated (Defensive)** (implement-specific)

   **Only when result.status == "implemented":**

   Check that the plan file status marker was updated to `[COMPLETED]`. If not, apply defensive correction.

   ```bash
   plan_file=$(ls -1 "specs/${PADDED_NUM}_${PROJECT_NAME}/plans/"*.md 2>/dev/null | sort -V | tail -1)

   if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
       if ! grep -qE '^\*\*Status\*\*: \[COMPLETED\]|^\- \*\*Status\*\*: \[COMPLETED\]' "$plan_file"; then
           echo "WARNING: Plan file status not updated to [COMPLETED]. Applying defensive correction."
           .claude/scripts/update-plan-status.sh "$task_number" "$PROJECT_NAME" "COMPLETED"
       fi
   fi
   ```

   **Skip if result.status == "partial":**
   Partial implementations do not need plan file verification.

6. **Verify TODO.md Status (Defensive)**

   **Only when result.status == "implemented":**

   Check that the task entry in TODO.md shows `[COMPLETED]`. If it still shows `[IMPLEMENTING]`, apply correction:

   ```bash
   if grep -q "- \*\*Status\*\*: \[IMPLEMENTING\]" <(grep -A 5 "^### ${task_number}\." specs/TODO.md); then
       echo "WARNING: TODO.md status not updated to [COMPLETED]. Applying defensive correction."
   fi
   ```

   If the check finds a mismatch, use Edit tool to fix both:
   - Task entry: `- **Status**: [IMPLEMENTING]` → `- **Status**: [COMPLETED]`
   - Task Order: `**{N}** [IMPLEMENTING]` → `**{N}** [COMPLETED]`

7. **Post-Delegation Takeover Detection (Future Work)**

   > **Note**: A future enhancement should detect if the skill performed source-file reads, builds, or codebase exploration after the subagent returned. If the skill's tool-call sequence shows Read/Grep/Glob/Bash operations on non-specs files after the Agent tool returned, log a warning: "Skill violated postflight boundary -- source operations detected after delegation." This is not currently enforced automatically but is documented as a desired GATE OUT validation.

**RETRY** skill if validation fails.

**On GATE OUT success**: Artifacts and completion summary verified. **IMMEDIATELY CONTINUE** to CHECKPOINT 3 below.

### CHECKPOINT 3: COMMIT

**On completion:**
```bash
git add -A
git commit -m "$(cat <<'EOF'
task {N}: complete implementation

Session: {SESSION_ID}

EOF
)"
```

**On partial:**
```bash
git add -A
git commit -m "$(cat <<'EOF'
task {N}: partial implementation (phases 1-{M} of {total})

Session: {SESSION_ID}

EOF
)"
```

Commit failure is non-blocking (log and continue).

## Output

**On Completion:**
```
Implementation complete for Task #{N}

Summary: specs/{NNN}_{SLUG}/summaries/MM_{short-slug}-summary.md

Phases completed: {phases_completed}/{phases_total}

Status: [COMPLETED]
```

**On Partial:**
```
Implementation paused for Task #{N}

Completed: Phases 1-{M}
Remaining: Phase {M+1}

Status: [IMPLEMENTING]
Next: /implement {N}
```

## Error Handling

### GATE IN Failure
- Task not found: Return error with guidance
- No plan found: Return error "Run /plan {N} first"
- Invalid status: Return error with current status

### DELEGATE Failure
- Skill fails: Keep [IMPLEMENTING], log error
- Timeout: Progress preserved in plan phase markers, user can re-run

### GATE OUT Failure
- Missing artifacts: Log warning, continue with available
- Link failure: Non-blocking warning

### Build Errors
- Skill returns partial/failed status
- Error details included in result
- User can fix issues and re-run /implement
