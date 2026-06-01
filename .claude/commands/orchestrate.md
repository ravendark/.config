---
description: Execute a task autonomously through its full lifecycle (research -> plan -> implement -> complete) without user confirmation between phases
allowed-tools: Skill, Agent, Bash(jq:*), Bash(git:*), Read
argument-hint: TASK_NUMBERS [PROMPT]
model: opus
---

# /orchestrate Command

Drive a task through its complete lifecycle autonomously without pausing for user confirmation.
Implements fire-and-forget state machine: research -> plan -> implement -> complete.

## Arguments

- `$1` - Task number(s) (required). Supports single task, comma-separated lists, and ranges.
  - Single: `42`
  - Comma-separated: `42, 43, 45`
  - Range: `42-45`
  - Mixed: `42, 44-46, 50`
- `$2+` - Optional prompt/focus text (e.g., `focus on the LSP config`). Applies to all tasks in multi-task mode.

## Constraints

- Multi-task mode uses dependency-aware wave dispatch. `--team` flag not supported.
- No confirmation gates between lifecycle phases
- Terminates automatically on success, MAX_CYCLES exceeded, or unrecoverable blocker
- In multi-task mode, failure in one task does not block other tasks in the same wave, but DOES block dependent tasks in later waves

## Anti-Bypass Constraint

**PROHIBITION**: All lifecycle phases (research, plan, implement) MUST be executed by delegating
to `skill-orchestrate` via the Skill tool. Never run research/plan/implement directly from this
command.

## Execution

### STAGE 0: PARSE AND DISPATCH

```bash
source .claude/scripts/parse-command-args.sh "$ARGUMENTS"
# Exports: TASK_NUMBERS (space-separated), FOCUS_PROMPT, REMAINING_ARGS
focus_prompt="${FOCUS_PROMPT:-}"
```

If `len(TASK_NUMBERS) == 1`: extract `task_number=$(echo "$TASK_NUMBERS" | awk '{print $1}')` and fall through to CHECKPOINT 1: GATE IN.

If `len(TASK_NUMBERS) > 1`: continue to MULTI-TASK DISPATCH below.

---

### MULTI-TASK DISPATCH

#### Step 1: Batch Validation

```bash
validated_tasks=(); skipped_tasks=()
for task_num in "${TASK_NUMBERS[@]}"; do
  task_data=$(jq -r --argjson num "$task_num" \
    '.active_projects[] | select(.project_number == $num)' specs/state.json)
  if [ -z "$task_data" ]; then
    skipped_tasks+=("$task_num: not found")
    continue
  fi
  status=$(echo "$task_data" | jq -r '.status')
  case "$status" in
    completed|abandoned|expanded)
      skipped_tasks+=("$task_num: terminal status [$status]")
      continue
      ;;
  esac
  validated_tasks+=("$task_num")
done
```

Report skipped tasks as warnings. If no validated tasks remain, ABORT with error.

#### Step 2: Dependency Graph Construction

For each task in `validated_tasks`, read its `dependencies` field from state.json. Restrict to **intra-batch dependencies only** (ignore dependencies on tasks not in `validated_tasks`):

```bash
# Build adjacency map: task -> list of validated predecessors it depends on
declare -A predecessors   # predecessors[$task] = space-separated list of intra-batch deps
declare -A in_degree      # in_degree[$task] = count of intra-batch predecessors

for task_num in "${validated_tasks[@]}"; do
  deps=$(jq -r --argjson num "$task_num" \
    '.active_projects[] | select(.project_number == $num) | .dependencies // [] | .[]' \
    specs/state.json)
  intra_deps=()
  for dep in $deps; do
    # Only include deps that are also in validated_tasks
    if [[ " ${validated_tasks[*]} " == *" $dep "* ]]; then
      intra_deps+=("$dep")
    fi
  done
  predecessors[$task_num]="${intra_deps[*]}"
  in_degree[$task_num]=${#intra_deps[@]}
done
```

#### Step 3: Topological Wave Assignment (Kahn's Algorithm)

```bash
# Initialize: collect tasks with no intra-batch predecessors into Wave 0
declare -A wave_assignment
waves=()
remaining=("${validated_tasks[@]}")

wave_num=0
while [ ${#remaining[@]} -gt 0 ]; do
  ready=()
  next_remaining=()

  for task in "${remaining[@]}"; do
    if [ "${in_degree[$task]}" -eq 0 ]; then
      ready+=("$task")
      wave_assignment[$task]=$wave_num
    else
      next_remaining+=("$task")
    fi
  done

  # Circular dependency detection: if no tasks are ready but remaining is non-empty
  if [ ${#ready[@]} -eq 0 ]; then
    echo "[ERROR] Circular dependency detected among tasks: ${remaining[*]}"
    echo "Aborting multi-task orchestration."
    return 1
  fi

  waves+=("${ready[*]}")
  remaining=("${next_remaining[@]}")

  # Decrement in-degree for tasks whose predecessor just completed this wave
  for completed in "${ready[@]}"; do
    for task in "${remaining[@]}"; do
      if [[ " ${predecessors[$task]} " == *" $completed "* ]]; then
        in_degree[$task]=$(( ${in_degree[$task]} - 1 ))
      fi
    done
  done

  wave_num=$(( wave_num + 1 ))
done
```

Wave assignment summary: tasks in Wave 0 have no intra-batch predecessors and run first. Tasks in Wave 1 depend only on Wave 0 tasks, and so on. All tasks within a wave are independent and can run in parallel.

#### Step 4: Wave Execution

Generate the batch session ID:

```bash
batch_session_id="sess_$(date +%s)_$(od -An -N3 -tx1 /dev/urandom | tr -d ' ')"
```

For each wave sequentially (Wave 0, then Wave 1, etc.):

1. **Check for skipped predecessors**: Before dispatching, check if any task in this wave has a predecessor that was skipped or failed. If yes, mark the task as skipped:
   ```
   for each task in wave:
     for each dep in predecessors[task]:
       if dep was skipped or failed:
         skipped_tasks += (task: "predecessor $dep failed/skipped")
         remove task from wave's dispatch list
   ```

2. **Dispatch remaining wave tasks in parallel**: Invoke all tasks in the wave simultaneously via concurrent Skill tool calls:
   ```
   For each task_num in wave (not skipped):
     Tool: Skill
     Parameters:
       skill: "skill-orchestrate"
       args: "task_number={task_num} session_id={batch_session_id}_{task_num} orchestrator_mode=true focus_prompt={focus_prompt}"
   ```

3. **Collect results**: After all parallel skill calls in the wave complete, record each task as succeeded or failed. A task is "failed" if its skill returns an error or its final status is not `completed`.

4. **Continue to next wave**: If a task failed, its direct dependents in later waves are skipped (see Step 4.1 for next wave).

#### Step 5: Batch Git Commit and Consolidated Output

After all waves complete, produce a batch git commit (non-blocking) and consolidated output.

**Batch Git Commit**:

Full success:
```bash
git add -A && git commit -m "orchestrate tasks {range_summary}: complete orchestration

Tasks: {comma-separated succeeded list}
Session: {batch_session_id}"
```

Partial success:
```bash
git add -A && git commit -m "orchestrate tasks {range_summary}: complete orchestration ({succeeded}/{total} succeeded)

Tasks completed: {comma-separated succeeded list}
Tasks failed: {num} ({reason})[, ...]
Tasks skipped: {num} ({reason})[, ...]
Session: {batch_session_id}"
```

**Consolidated Output**:

```markdown
## Batch Orchestrate Results

Session: {batch_session_id}
Tasks requested: {count}
Succeeded: {count}
Failed: {count}
Skipped: {count}

### Succeeded

| Task | Title | Final Status | Cycles |
|------|-------|--------------|--------|
| #42 | task_title | [COMPLETED] | 3/5 |

### Failed

| Task | Wave | Error |
|------|------|-------|
| #43 | 1 | Agent timeout after MAX_CYCLES |

### Skipped

| Task | Reason |
|------|--------|
| #44 | predecessor #43 failed |
| #99 | terminal status [ABANDONED] |

### Next Steps
- Re-run failed tasks: /orchestrate {failed_task_numbers}
```

**After consolidated output, STOP. Do not continue to CHECKPOINT 1.**

---

### CHECKPOINT 1: GATE IN

```bash
source .claude/scripts/command-gate-in.sh "$task_number" "orchestrate"
# Exports: SESSION_ID, TASK_TYPE, TASK_STATUS, PROJECT_NAME, DESCRIPTION, PADDED_NUM
# Displays: [ORCHESTRATE] Task {N}: {project_name}
```

**Permissive gate**: Unlike `/implement`, this command does NOT require a plan file.
The state machine handles all lifecycle phases starting from wherever the task currently is.

**Only blocks on terminal states**: `completed`, `abandoned`, `expanded`.
All non-terminal states (not_started, researched, planned, implementing, partial, blocked) are
valid entry points for the orchestrator.

**On GATE IN success**: Task validated. **IMMEDIATELY CONTINUE** to STAGE 2.

### STAGE 2: DELEGATE

**EXECUTE NOW**: After CHECKPOINT 1 completes, immediately invoke the Skill tool.

Invoke `skill-orchestrate` via the Skill tool:

```
skill: "skill-orchestrate"
args: "task_number={N} session_id={SESSION_ID} orchestrator_mode=true"
```

The delegation context passed to the skill must include:
```json
{
  "session_id": "{SESSION_ID}",
  "delegation_depth": 1,
  "delegation_path": ["orchestrator", "orchestrate", "skill-orchestrate"],
  "task_context": {
    "task_number": N,
    "task_name": "{PROJECT_NAME}",
    "description": "{DESCRIPTION}",
    "task_type": "{TASK_TYPE}"
  },
  "orchestrator_mode": true,
  "focus_prompt": "{FOCUS_PROMPT}"
}
```

**On DELEGATE success**: Orchestration complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 2.

### CHECKPOINT 2: GATE OUT

```bash
bash .claude/scripts/command-gate-out.sh "$task_number" "orchestrate" "$SESSION_ID"
# Reads .return-meta.json; applies defensive status correction if needed
```

**Populate Completion Summary (if implemented)**:

```bash
completion_summary="$result_summary"
jq --arg summary "$completion_summary" \
  '(.active_projects[] | select(.project_number == '"$task_number"')).completion_summary = $summary' \
  specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
```

**On GATE OUT success**: IMMEDIATELY CONTINUE to CHECKPOINT 3.

### CHECKPOINT 3: COMMIT

**On completion:**
```bash
git add -A && git commit -m "task {N}: complete orchestration

Session: {SESSION_ID}"
```

**On partial:**
```bash
git add -A && git commit -m "task {N}: orchestration paused (cycles {M}/{MAX})

Session: {SESSION_ID}"
```

Commit failure is non-blocking (log and continue).

## Output

**Completion**: `Orchestration complete for Task #{N}` | Final status: `[COMPLETED]` | Cycles: M/5

**Partial**: `Orchestration paused for Task #{N}` | Status: `[{STATUS}]` | Cycles: M/5 | `Next: /orchestrate {N}`

**Blocked**: `Task #{N} requires manual intervention` | Blocker description | Suggested actions

## Error Handling

- **GATE IN Failure**: Task not found or in terminal state — return error with guidance
- **DELEGATE Failure**: Keep current status, log error; loop guard preserved for resume
- **GATE OUT Failure**: Missing artifacts — log warning, continue with available
- **MAX_CYCLES Reached**: Report status, provide `/orchestrate {N}` resume instruction
