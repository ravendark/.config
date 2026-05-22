---
description: Research a task and create reports
allowed-tools: Skill, Agent, Bash(jq:*), Bash(git:*), Read, Edit
argument-hint: TASK_NUMBERS [FOCUS] [--team [--team-size N]] [--fast|--hard] [--haiku|--sonnet|--opus]
model: opus
---

# /research Command

Conduct research for a task by delegating to the appropriate research skill/subagent.

## Arguments

- `$1` - Task number(s) (required). Supports single task, comma-separated lists, and ranges.
- Remaining args - Optional focus/prompt for research direction (applies to all tasks in multi-task mode)

### Multi-Task Syntax

| Input | Tasks | Mode |
|-------|-------|------|
| `7` | 7 | single |
| `7, 22-24, 59` | 7, 22, 23, 24, 59 | multi |
| `7 focus on APIs` | 7 | single (with focus) |
| `7, 22-24 --team` | 7, 22, 23, 24 | multi (with team) |

When multiple tasks are specified, each task is researched independently in parallel. Flags and focus prompts apply uniformly to all tasks.

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--team` | Enable multi-agent parallel research with multiple teammates | false |
| `--team-size N` | Number of teammates to spawn (2-4) | 2 |
| `--fast` | Low-effort mode: lighter reasoning, faster responses | false |
| `--hard` | High-effort mode: deeper reasoning, more thorough analysis | false |
| `--haiku` | Use Haiku model (fastest, lowest cost) | false |
| `--sonnet` | Use Sonnet model (balanced cost/quality) | false |
| `--opus` | Use Opus model (highest quality, same as agent default) | false |
| `--clean` | Skip automatic memory and roadmap retrieval | false |

When `--team` is specified, research is delegated to `skill-team-research` which spawns multiple research agents working in parallel on different aspects of the task. Each teammate produces a research report, and the lead synthesizes findings into a final comprehensive report.

**Note**: Team mode requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable. If unavailable, gracefully degrades to single-agent research.

## Anti-Bypass Constraint

**PROHIBITION**: You MUST NOT write research report artifacts directly using Write or Edit tools. All report files MUST be created by invoking the appropriate skill (skill-researcher or skill-team-research) via the Skill tool.

**Why**: Direct writes bypass format enforcement (validate-artifact.sh), produce non-conforming artifacts missing required metadata fields and sections, and circumvent the delegation chain that ensures quality. A PostToolUse hook monitors all Write/Edit operations to artifact paths and will flag violations with corrective context.

**Required**: Always delegate to the Skill tool. Never write to `specs/*/reports/*.md` directly from this command.

## Execution

**Note**: Delegate to skills for task-type-specific research.

### STAGE 0: PARSE TASK NUMBERS

Parse the raw argument string to separate task numbers from remaining arguments (flags and focus prompts).

```bash
source .claude/scripts/parse-command-args.sh "$ARGUMENTS"
# Exports: TASK_NUMBERS, REMAINING_ARGS, TEAM_MODE, TEAM_SIZE, EFFORT_FLAG, MODEL_FLAG,
#          CLEAN_FLAG, FORCE_FLAG, FOCUS_PROMPT
# Note: per-command team-size max clamp for research (max 4):
[ "$TEAM_SIZE" -gt 4 ] && TEAM_SIZE=4
```

**Dispatch Decision**:

```
if len(TASK_NUMBERS) == 1:
    # SINGLE-TASK MODE
    task_number = TASK_NUMBERS[0]
    # Fall through to CHECKPOINT 1: GATE IN below

elif len(TASK_NUMBERS) > 1:
    # MULTI-TASK MODE
    # Continue to MULTI-TASK DISPATCH below
    # Do NOT enter CHECKPOINT 1
```

**On single task**: Fall through to CHECKPOINT 1: GATE IN below (existing flow unchanged).
**On multiple tasks**: Branch to MULTI-TASK DISPATCH section below. After dispatch completes, skip directly to output (do not enter single-task checkpoints).

---

### MULTI-TASK DISPATCH

When `parse-command-args.sh` produces more than one task number in TASK_NUMBERS, execute batch research.

#### Step 1: Batch Validation

Validate all tasks exist and have valid status for research:

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

  # Block terminal statuses only
  case "$status" in
    completed|abandoned|expanded) skipped_tasks+=("$task_num: terminal status [$status]") ; continue ;;
  esac
  validated_tasks+=("$task_num")
done
```

Report skipped tasks as warnings. If no validated tasks remain, ABORT.

#### Step 2: Generate Batch Session ID

```bash
batch_session_id="sess_$(date +%s)_$(od -An -N3 -tx1 /dev/urandom | tr -d ' ')"
```

#### Step 3: Dispatch Skills

For each validated task, invoke the appropriate research skill using parallel Skill tool calls from the orchestrator's built-in batch loop:

1. Extract task_type per task from state.json
2. Route to the appropriate research skill per task (extension routing or default `skill-researcher`)
3. Invoke all skills in a single message (parallel execution, one skill per task)
4. Each skill runs the full single-task research lifecycle independently (preflight, agent delegation, postflight)
5. Collect text results from all skills; read `.return-meta.json` in each task directory for structured data if needed

**Note**: Batch dispatch is handled directly by this command's orchestrator loop via parallel Skill tool calls, not by a separate batch skill.

**Team mode interaction**: If `--team` is in `remaining_args`, team mode is applied to ALL tasks (each task routes to `skill-team-research`). Total agents spawned = `N_tasks * team_size`. Use with care due to cost multiplication.

#### Step 4: Batch Git Commit

After all skills complete, produce a single batch commit. Per-skill postflight may have already committed individual task changes; this batch commit captures any remaining unstaged changes and may be empty (which fails gracefully).

**Full success**:
```
research tasks {range_summary}: complete research

Tasks: {comma-separated list}
Session: {batch_session_id}
```

**Partial success**:
```
research tasks {range_summary}: complete research ({succeeded}/{total} succeeded)

Tasks completed: {comma-separated}
Tasks failed: {num} ({reason})[, {num} ({reason})]
Session: {batch_session_id}
```

#### Step 5: Consolidated Output

Display batch results and exit (do not enter single-task checkpoints):

```markdown
## Batch Research Results

Session: {batch_session_id}
Tasks requested: {count}
Succeeded: {count}
Failed: {count}
Skipped: {count}

### Succeeded

| Task | Title | Status | Artifact |
|------|-------|--------|----------|
| #7 | task_title | [RESEARCHED] | specs/007_slug/reports/01_short.md |

### Failed

| Task | Error |
|------|-------|
| #23 | Agent timeout |

### Skipped

| Task | Reason |
|------|--------|
| #99 | Not found in state.json |

### Next Steps
- /plan {succeeded_task_numbers}
```

#### Error Handling (Multi-Task)

- **Partial success is normal**: Failure of one task does not block or roll back others
- **Failed tasks**: Remain in "researching" status; user can re-run individually (`/research {N}`)
- **Skipped tasks**: Never dispatched; user fixes the issue and re-runs
- **Git conflicts**: Non-blocking (logged, not fatal)

---

### CHECKPOINT 1: GATE IN

```bash
source .claude/scripts/command-gate-in.sh "$task_number" "research"
# Exports: SESSION_ID, TASK_TYPE, TASK_STATUS, PROJECT_NAME, DESCRIPTION, PADDED_NUM
# Displays: [RESEARCH] Task {N}: {project_name}
# Aborts if task not found or in terminal status
```

**On GATE IN success**: Task validated. **IMMEDIATELY CONTINUE** to STAGE 2 below.

### STAGE 2: DELEGATE

**EXECUTE NOW**: After CHECKPOINT 1 completes, immediately invoke the Skill tool.

**Team Mode Routing** (when `--team` flag present):

If `TEAM_MODE == "true"`:
- Route to `skill-team-research` regardless of task_type
- Pass `TEAM_SIZE` parameter

**Extension Routing** (when `--team` flag NOT present):

Check extension manifests for task-type-specific research routing:

```bash
# TASK_TYPE is exported by command-gate-in.sh
# (may be simple "founder" or compound "founder:deck")

# Check extension routing for research (skill_name starts empty)
skill_name=""
for manifest in .claude/extensions/*/manifest.json; do
  if [ -f "$manifest" ]; then
    ext_skill=$(jq -r --arg tt "$TASK_TYPE" \
      '.routing.research[$tt] // empty' "$manifest")
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
        '.routing.research[$tt] // empty' "$manifest")
      if [ -n "$ext_skill" ]; then
        skill_name="$ext_skill"
        break
      fi
    fi
  done
fi

# Fallback to default researcher if no extension routing found
skill_name=${skill_name:-"skill-researcher"}
```

**Extension-Based Routing Table**:

| Task Type | Skill to Invoke |
|-----------|-----------------|
| `founder` | `skill-market` (from founder extension) |
| `founder:deck` | `skill-deck-research` (from founder extension) |
| `founder:analyze` | `skill-analyze` (from founder extension) |
| `founder:strategy` | `skill-strategy` (from founder extension) |
| `founder:{sub-type}` | Compound key lookup, falls back to `skill-market` |
| `general`, `meta`, `markdown` | `skill-researcher` (default) |

**Skill Selection Logic**:
```
if TEAM_MODE == "true":
  skill_name = "skill-team-research"
else:
  skill_name = {extension routing lookup} OR "skill-researcher"
```

**Invoke the Skill tool NOW** with:
```
# For team mode:
skill: "skill-team-research"
args: "task_number={N} focus={FOCUS_PROMPT} team_size={TEAM_SIZE} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG}"

# For single-agent mode:
skill: "{skill-name from table above}"
args: "task_number={N} focus={FOCUS_PROMPT} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG}"
```

If `MODEL_FLAG` is set, pass the `model` parameter to override the agent's default model:
- `MODEL_FLAG="haiku"` -> pass `model: haiku`
- `MODEL_FLAG="sonnet"` -> pass `model: sonnet`
- `MODEL_FLAG="opus"` -> pass `model: opus`
- `MODEL_FLAG=""` -> omit `model` parameter (use agent's frontmatter default: opus for planner/meta-builder/reviser; sonnet for general-purpose agents)

If `EFFORT_FLAG` is set, pass it as prompt context to the skill/agent for reasoning depth guidance.

The skill will spawn the appropriate agent(s) to conduct research and create a report.

**On DELEGATE success**: Research complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

```bash
bash .claude/scripts/command-gate-out.sh "$task_number" "research" "$SESSION_ID"
# Reads .return-meta.json; applies defensive status correction if needed
# Runs validate-artifact.sh --fix (non-blocking)
```

1. **Verify state.json Status (Defensive)**

   **Only when skill reports success:**

   Check that state.json shows status "researched" for this task. If not, apply defensive correction:

   ```bash
   current_status=$(jq -r --argjson num "$task_number" \
     '.active_projects[] | select(.project_number == $num) | .status' \
     specs/state.json)

   if [ "$current_status" != "researched" ]; then
       echo "WARNING: state.json status is '$current_status', expected 'researched'. Applying defensive correction."
       bash .claude/scripts/update-task-status.sh postflight "$task_number" research "$SESSION_ID"
   fi
   ```

2. **Verify TODO.md Status (Defensive)**

   **Only when skill reports success:**

   Check that the task entry in TODO.md shows `[RESEARCHED]`. If it still shows `[RESEARCHING]`, apply correction:

   ```bash
   if grep -q "- \*\*Status\*\*: \[RESEARCHING\]" <(grep -A 5 "^### ${task_number}\." specs/TODO.md); then
       echo "WARNING: TODO.md status not updated to [RESEARCHED]. Applying defensive correction."
   fi
   ```

   If the check finds a mismatch, use Edit tool to fix both:
   - Task entry: `- **Status**: [RESEARCHING]` -> `- **Status**: [RESEARCHED]`
   - Task Order: `**{N}** [RESEARCHING]` -> `**{N}** [RESEARCHED]`

**RETRY** skill if validation fails.

**On GATE OUT success**: Artifacts verified. **IMMEDIATELY CONTINUE** to CHECKPOINT 3 below.

### CHECKPOINT 3: COMMIT

```bash
git add -A
git commit -m "$(cat <<'EOF'
task {N}: complete research

Session: {SESSION_ID}

EOF
)"
```

Commit failure is non-blocking (log and continue).

## Output

```
Research completed for Task #{N}

Report: specs/{NNN}_{SLUG}/reports/MM_{short-slug}.md

Status: [RESEARCHED]
Next: /plan {N}
```

## Error Handling

### GATE IN Failure
- Task not found: Return error with guidance
- Invalid status: Return error with current status

### DELEGATE Failure
- Skill fails: Keep [RESEARCHING], log error
- Timeout: Partial research preserved, user can re-run

### GATE OUT Failure
- Missing artifacts: Log warning, continue with available
- Link failure: Non-blocking warning
