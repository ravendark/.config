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

## Anti-Bypass Constraint

**PROHIBITION**: You MUST NOT write research report artifacts directly using Write or Edit tools. All report files MUST be created by invoking the appropriate skill (skill-researcher or skill-team-research) via the Skill tool.

**Required**: Always delegate to the Skill tool. Never write to `specs/*/reports/*.md` directly from this command.

## Execution

**Note**: Delegate to skills for task-type-specific research.

### STAGE 0: PARSE TASK NUMBERS

```bash
source .claude/scripts/parse-command-args.sh "$ARGUMENTS"
# Exports: TASK_NUMBERS, REMAINING_ARGS, TEAM_MODE, TEAM_SIZE, EFFORT_FLAG, MODEL_FLAG,
#          CLEAN_FLAG, FORCE_FLAG, FOCUS_PROMPT
[ "$TEAM_SIZE" -gt 4 ] && TEAM_SIZE=4
```

If `len(TASK_NUMBERS) > 1`: continue to MULTI-TASK DISPATCH below.
If `len(TASK_NUMBERS) == 1`: fall through to CHECKPOINT 1: GATE IN.

---

### MULTI-TASK DISPATCH

#### Step 1: Batch Validation

```bash
validated_tasks=(); skipped_tasks=()
for task_num in "${task_numbers[@]}"; do
  task_data=$(jq -r --argjson num "$task_num" '.active_projects[] | select(.project_number == $num)' specs/state.json)
  if [ -z "$task_data" ]; then skipped_tasks+=("$task_num: not found"); continue; fi
  status=$(echo "$task_data" | jq -r '.status')
  case "$status" in completed|abandoned|expanded) skipped_tasks+=("$task_num: terminal status [$status]"); continue ;; esac
  validated_tasks+=("$task_num")
done
```

Report skipped tasks as warnings. If no validated tasks remain, ABORT.

#### Step 2: Generate Batch Session ID

```bash
batch_session_id="sess_$(date +%s)_$(od -An -N3 -tx1 /dev/urandom | tr -d ' ')"
```

#### Step 3: Dispatch Skills

For each validated task, invoke the appropriate research skill using parallel Skill tool calls:
1. Extract task_type per task from state.json
2. Route using extension manifests or default `skill-researcher` (if `--team`: use `skill-team-research`)
3. Invoke all skills in a single message (parallel execution, one skill per task)
4. Collect text results from all skills; read `.return-meta.json` for structured data

#### Step 4: Batch Git Commit and Consolidated Output

After all skills complete, git commit any remaining changes (non-blocking), then display:

```markdown
## Batch Research Results
Session: {batch_session_id}
Tasks requested / Succeeded / Failed / Skipped: {counts}
### Succeeded / Failed / Skipped: {tables}
### Next Steps: /plan {succeeded_task_numbers}
```

**After consolidated output, STOP.** Do not continue to CHECKPOINT 1.

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

**Team Mode Routing** (when `--team` flag present): Route to `skill-team-research`.

**Extension Routing** (when `--team` flag NOT present):

```bash
source .claude/scripts/command-route-skill.sh "research" "$TASK_TYPE" "skill-researcher"
skill_name="$SKILL_NAME"
# Defensive correction (state.json + TODO.md) handled by command-gate-out.sh
```

**Routing table**:

| Task Type | Skill to Invoke |
|-----------|-----------------|
| `neovim` | `skill-neovim-research` |
| `nix` | `skill-nix-research` |
| `general`, `meta`, `markdown` | `skill-researcher` (default) |
| Extension type | Resolved via extension manifest routing |

**Invoke the Skill tool NOW** with:
```
# For team mode:
skill: "skill-team-research"
args: "task_number={N} focus={FOCUS_PROMPT} team_size={TEAM_SIZE} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG} orchestrator_mode=false"

# For single-agent mode:
skill: "{skill_name}"
args: "task_number={N} focus={FOCUS_PROMPT} session_id={SESSION_ID} effort_flag={EFFORT_FLAG} model_flag={MODEL_FLAG} clean_flag={CLEAN_FLAG} orchestrator_mode=false"
```

Pass `model` parameter if `MODEL_FLAG` is set. Pass `effort_flag` as prompt context if set.

**On DELEGATE success**: Research complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 2 below.

### CHECKPOINT 2: GATE OUT

```bash
bash .claude/scripts/command-gate-out.sh "$task_number" "research" "$SESSION_ID"
# Reads .return-meta.json; applies defensive status correction if needed
# Runs validate-artifact.sh --fix (non-blocking)
# Defensive correction (state.json + TODO.md) handled by this script
```

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

- **GATE IN Failure**: Task not found or invalid status — return error with guidance
- **DELEGATE Failure**: Skill fails — keep [RESEARCHING], log error; timeout — partial research preserved, user can re-run
- **GATE OUT Failure**: Missing artifacts — log warning, continue with available
