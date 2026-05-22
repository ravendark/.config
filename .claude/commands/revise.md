---
description: Create new version of implementation plan, or update task description if no plan exists
allowed-tools: Skill, Bash(jq:*), Bash(git:*), Bash(source:*), Bash(bash:*), Read, Edit, Glob
argument-hint: TASK_NUMBER [--orchestrator] [REASON]
model: opus
---

# /revise Command

Create a new version of an implementation plan, or update task description if no plan exists.

**Artifact Numbering Note**: Plan revision creates a new plan file within the same artifact round.
The revised plan uses the SAME artifact number (not incremented) because it replaces the previous
plan in the same round. Only `/research` advances the artifact number to start a new round.
Shared gate-in/gate-out infrastructure is provided by `.claude/scripts/command-gate-in.sh` and
`.claude/scripts/command-gate-out.sh`.

## Arguments

- `$1` - Task number (required)
- `--orchestrator` - Optional flag; when set, writes `.orchestrator-handoff.json` for skill-orchestrate
- Remaining args - Optional reason for revision

## Execution

### CHECKPOINT 1: GATE IN

```bash
# Parse arguments
task_number="$1"
orchestrator_mode="false"
revision_reason=""
shift
for arg in "$@"; do
  if [ "$arg" = "--orchestrator" ]; then
    orchestrator_mode="true"
  else
    revision_reason="${revision_reason:+$revision_reason }$arg"
  fi
done

# Shared gate-in: generates SESSION_ID, exports PADDED_NUM, PROJECT_NAME, TASK_STATUS, TASK_TYPE
source .claude/scripts/command-gate-in.sh "$task_number" "revise"
# Exits with error if task not found or in terminal status

# Check plan existence (determines routing)
plan_exists=$(ls specs/${PADDED_NUM}_${PROJECT_NAME}/plans/*.md 2>/dev/null | head -1)
```

**PROCEED** to delegation.

---

### CHECKPOINT 2: DELEGATE TO SKILL

Invoke `skill-reviser` with the validated task context. The skill delegates to `reviser-agent` which handles:

- **Plan Revision path**: Load current plan, discover new research, synthesize revised plan
- **Description Update path**: Update task description based on revision reason

```
skill: "skill-reviser"
args: "task_number={N} session_id=$SESSION_ID revision_reason={reason} plan_exists={true|false} orchestrator_mode=$orchestrator_mode"
```

The skill spawns the reviser-agent, handles postflight (status update, artifact linking, git commit), and returns a brief text summary. The `plan_exists` flag routes between Plan Revision and Description Update paths. The `orchestrator_mode` flag is passed through so the skill can write the handoff at postflight time.

**On DELEGATE success**: Revision complete. **IMMEDIATELY CONTINUE** to CHECKPOINT 3 below.

---

### CHECKPOINT 3: GATE OUT

```bash
# Shared gate-out: defensive status correction and artifact validation
bash .claude/scripts/command-gate-out.sh "$task_number" "plan" "$SESSION_ID"
```

1. **Verify Artifacts** (Plan Revision only)
   If `plan_exists` was true (plan revision path), check the revised plan file exists on disk:
   ```bash
   revised_plan=$(ls -1t specs/${PADDED_NUM}_${PROJECT_NAME}/plans/*.md 2>/dev/null | head -1)
   if [ -z "$revised_plan" ]; then
       echo "WARNING: No plan file found after revision."
   fi
   ```

2. **Orchestrator Handoff** (if `--orchestrator` flag was set)
   ```bash
   if [ "$orchestrator_mode" = "true" ]; then
     source .claude/scripts/skill-base.sh
     skill_write_orchestrator_handoff \
       "true" "$PADDED_NUM" "$PROJECT_NAME" \
       "revise" "planned" \
       "Plan revised for task $task_number." \
       "$revised_plan" "plan" \
       "implement"
   fi
   ```

**On GATE OUT success**: Revision verified.

---

## Output

**Plan Revision**: `Plan revised for Task #{N}` — previous/new file names, preserved/revised phases, status `[PLANNED]`, `Next: /implement {N}`

**Description Update**: `Description updated for Task #{N}` — previous/new description text, current status

## Error Handling

### GATE IN Failure
- Task not found: Return error with guidance
- Terminal status: Blocked by gate-in guard

### DELEGATE Failure
- skill-reviser handles all error cases internally
- Missing plan for revision: Agent falls back to description update
- Write failure: Agent logs error, preserves original
- Git commit failure: Non-blocking (logged by skill)

### GATE OUT Failure
- Missing artifacts: Log warning, continue with available
- Status mismatch: Applied defensively via command-gate-out.sh
