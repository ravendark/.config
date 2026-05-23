---
name: skill-team-plan
description: Orchestrate multi-agent planning with parallel plan generation. Spawns 2-3 teammates for diverse planning approaches and synthesizes into final plan with trade-off analysis.
allowed-tools: Agent, Bash, Edit, Read, Write
# This skill uses Agent tool for team coordination (available when CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
# Context loaded by lead during synthesis:
#   - .claude/context/patterns/team-orchestration.md
#   - .claude/context/formats/team-metadata-extension.md
#   - .claude/context/reference/team-wave-helpers.md
---

# Team Plan Skill

Multi-agent planning with wave-based parallelization. Spawns 2-3 teammates to generate alternative plans, then synthesizes into a final plan with trade-off analysis.

**IMPORTANT**: This skill requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable. If team creation fails, gracefully degrades to single-agent planning via skill-planner.

## Context References

Reference (load as needed during synthesis):
- Path: `.claude/context/patterns/team-orchestration.md` - Wave coordination patterns
- Path: `.claude/context/formats/team-metadata-extension.md` - Team result schema
- Path: `.claude/context/formats/return-metadata-file.md` - Base metadata schema
- Path: `.claude/context/reference/team-wave-helpers.md` - Reusable wave patterns

## Trigger Conditions

This skill activates when:
- `/plan N --team` is invoked
- Task exists and status allows planning
- Team mode is requested via --team flag

## Input Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `task_number` | integer | Yes | Task to plan |
| `research_path` | string | No | Path to research report |
| `team_size` | integer | No | Number of teammates (2-3, default 2) |
| `session_id` | string | Yes | Session ID for tracking |
| `model_flag` | string | No | Model override (haiku, sonnet, opus). If set, use instead of default |
| `effort_flag` | string | No | Effort level (fast, hard). Passed as prompt context |

**Model Selection**: Determine teammate model early:
```bash
# Use model_flag if provided, otherwise default to sonnet (cost-effective for team mode)
teammate_model="${model_flag:-sonnet}"
model_preference_line="Model preference: Use Claude ${teammate_model^} 4.6 for this task."
```

---

## Execution Flow

### Stage 1: Input Validation

Validate required inputs:
- `task_number` - Must exist in state.json
- `team_size` - Clamp to range [2, 3], default 2

```bash
# Lookup task
task_data=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num)' \
  specs/state.json)

if [ -z "$task_data" ]; then
  return error "Task $task_number not found"
fi

# Extract fields
task_type=$(echo "$task_data" | jq -r '.task_type // "general"')
status=$(echo "$task_data" | jq -r '.status')
project_name=$(echo "$task_data" | jq -r '.project_name')
description=$(echo "$task_data" | jq -r '.description // ""')

# Validate team_size (2-3 for planning)
team_size=${team_size:-2}
[ "$team_size" -lt 2 ] && team_size=2
[ "$team_size" -gt 3 ] && team_size=3
```

---

### Stage 2: Preflight Status Update

Update task status to "planning" BEFORE spawning teammates.

```bash
bash .claude/scripts/update-task-status.sh preflight "$task_number" plan "$session_id"
```

---

### Stage 3: Create Postflight Marker

Create marker file to prevent premature termination:

```bash
padded_num=$(printf "%03d" "$task_number")
mkdir -p "specs/${padded_num}_${project_name}"

cat > "specs/${padded_num}_${project_name}/.postflight-pending" << EOF
{
  "session_id": "${session_id}",
  "skill": "skill-team-plan",
  "task_number": ${task_number},
  "operation": "team-plan",
  "team_size": ${team_size},
  "reason": "Team planning in progress: synthesis, status update, git commit pending"
}
EOF
```

---

### Stage 4: Check Team Mode Availability

Verify Agent Teams feature is available:

```bash
# Check environment variable
if [ "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" != "1" ]; then
  echo "Warning: Team mode unavailable, falling back to single agent"
  # Fall back to skill-planner (see Stage 4a)
fi
```

---

### Stage 4a: Fallback to Single Agent

If team mode is unavailable:

1. Log warning about degradation
2. Invoke `skill-planner` via Skill tool
3. Pass original parameters
4. Add `degraded_to_single: true` to metadata
5. Continue with postflight

---

### Stage 5a: Calculate Artifact Number

Read `next_artifact_number` from state.json and use (current-1) since plan stays in the same round as research:

```bash
# Read next_artifact_number from state.json
next_num=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num) | .next_artifact_number // 1' \
  specs/state.json)

# Plan uses (current - 1) to stay in the same round as research
# If next_artifact_number is 1 (no research yet), use 1
if [ "$next_num" -le 1 ]; then
  artifact_number=1
else
  artifact_number=$((next_num - 1))
fi

# Fallback for legacy tasks: count existing plan artifacts
if [ "$next_num" = "null" ] || [ -z "$next_num" ]; then
  padded_num=$(printf "%03d" "$task_number")
  count=$(ls "specs/${padded_num}_${project_name}/plans/"*[0-9][0-9]*.md 2>/dev/null | wc -l)
  artifact_number=$((count + 1))
fi

run_padded=$(printf "%02d" "$artifact_number")
# run_padded is now the artifact number for this team planning run (e.g., "01")
```

**Note**: Team plan does NOT increment `next_artifact_number`. Only research advances the sequence.

---

### Stage 5: Spawn Planning Wave

Create teammate prompts and spawn wave. Pass `artifact_number`, `teammate_letter`, and `research_path` (as @-reference) to each teammate. Do NOT read the research file content into the lead — teammates read it in their own contexts.

**Delegation context for teammates**:
```json
{
  "artifact_number": "{run_padded}",
  "teammate_letter": "a",
  "artifact_pattern": "{NN}_candidate-{letter}.md"
}
```

**Teammate A - Plan Version A (Incremental Delivery)**:
```
Create an implementation plan for task {task_number}: {description}

{model_preference_line}

Artifact number: {run_padded}
Teammate letter: a

Focus on incremental delivery with verification at each phase.
Each phase should deliver working, tested functionality.
Consider dependencies between phases.

Read the research report for context: @{research_path}

Output your plan to:
specs/{NNN}_{SLUG}/plans/{run_padded}_candidate-a.md

Follow the plan format in @.claude/context/formats/plan-format.md
```

**Teammate B - Plan Version B (Alternative Boundaries)**:
```
Create an alternative implementation plan for task {task_number}: {description}

{model_preference_line}

Artifact number: {run_padded}
Teammate letter: b

Consider different phase boundaries or ordering.
Look for opportunities to parallelize phases.
Focus on risk mitigation through early verification.

Read the research report for context: @{research_path}

Do NOT duplicate Teammate A's exact phase structure.
Provide a meaningfully different approach.

Output your plan to:
specs/{NNN}_{SLUG}/plans/{run_padded}_candidate-b.md

Follow the plan format in @.claude/context/formats/plan-format.md
```

**Teammate C - Risk/Dependency Analysis (if team_size >= 3)**:
```
Analyze dependencies and risks for implementing task {task_number}: {description}

{model_preference_line}

Artifact number: {run_padded}
Teammate letter: c

Identify:
- Which phases can be parallelized vs must be sequential
- Critical path through the implementation
- High-risk phases requiring extra verification
- External dependencies that could block progress

Read the research report for context: @{research_path}

Output your analysis to:
specs/{NNN}_{SLUG}/plans/{run_padded}_risk-analysis.md

Format: Risk analysis with dependency graph and critical path
```

---

**Spawn teammates using Agent tool**.

**IMPORTANT**: Pass the `model` parameter to enforce model selection:
- Use `model: "sonnet"` for all tasks

**Synthesis uses base number without letter**: After all teammates complete, the synthesis plan uses `{run_padded}_{slug}.md` (e.g., `01_implementation-plan.md`).

---

### Stage 6: Wait for Wave Completion

Wait for all teammates to complete or timeout:

```
Timeout: 30 minutes for Wave 1

While not all complete and not timed out:
  - Check teammate completion status
  - Collect completed results
  - Wait 30 seconds between checks

On timeout:
  - Mark remaining as "timeout"
  - Continue with available results
```

---

### Stage 7: Collect Teammate Result Paths

After all teammates complete, collect only the file paths of completed candidate plans. Do NOT read the files themselves — delegate to synthesis-agent.

```bash
padded_num=$(printf "%03d" "$task_number")
candidate_paths=""
completed_count=0
failed_count=0

for candidate in a b; do
  file="specs/${padded_num}_${project_name}/plans/${run_padded}_candidate-${candidate}.md"
  if [ -f "$file" ]; then
    candidate_paths="${candidate_paths}
- @${file}"
    completed_count=$((completed_count + 1))
  else
    failed_count=$((failed_count + 1))
  fi
done

# Also check for risk analysis if team_size >= 3
if [ "$team_size" -ge 3 ]; then
  file="specs/${padded_num}_${project_name}/plans/${run_padded}_risk-analysis.md"
  if [ -f "$file" ]; then
    candidate_paths="${candidate_paths}
- @${file}"
  fi
fi

output_path="specs/${padded_num}_${project_name}/plans/${run_padded}_implementation-plan.md"
mkdir -p "specs/${padded_num}_${project_name}/plans/"
```

**Lead context growth from this stage**: ~100 tokens per candidate (file paths only, no content).

---

### Stage 8: Dispatch Synthesis Agent

Dispatch the synthesis agent with candidate plan paths as @-references. The synthesis agent reads all candidate files in its own fresh context and writes the unified plan.

```
Agent(
  subagent_type: "synthesis-agent",
  prompt: "Synthesize team planning for task {task_number}: {description}

## Candidate Plans

Read each of the following candidate plan files:
{candidate_paths}

## Context

Task description: {description}
Task type: {task_type}
Team size: {team_size}
Research report: @{research_path} (read for context if provided)

## Output

Write the unified implementation plan to:
{output_path}

Follow the plan format in @.claude/context/formats/plan-format.md

Include a Trade-off Analysis section comparing candidate approaches and explaining which elements were selected and why.

## Return

After writing the plan, return a compact summary (under 200 words) with:
- Selected approach and rationale
- Phase count in final plan
- Key trade-offs resolved
- Full path to the written plan",
  model: "{teammate_model}",
  timeout: 900
)
```

---

### Stage 9: Record Synthesis Result

Receive the compact summary (under 200 words) from the synthesis agent and extract:

- `artifact_path`: The output path reported by the synthesis agent
- `synthesis_summary`: The compact text summary

Store these for postflight use. The lead does NOT read the unified plan file.

**Lead context growth from synthesis**: ~200 tokens (synthesis summary only).

On synthesis failure:
- Set `artifact_path` to the most complete candidate plan (prefer candidate-a)
- Set `synthesis_failed = true` for postflight metadata
- Continue to postflight with `partial` status

---

### Stage 10: Update Status (Postflight)

Update task status to "planned" using skill-base.sh functions:

```bash
source .claude/scripts/skill-base.sh

# Step 1: Update status in state.json and TODO.md
skill_postflight_update "$task_number" "plan" "$session_id" "planned"

# Step 2: Link synthesis artifact in state.json and TODO.md
artifact_summary="Team planning with ${team_size} teammates and trade-off analysis"
skill_link_artifacts "$task_number" "$artifact_path" "plan" "$artifact_summary" "'**Plan**'" "'**Description**'"
```

---

### Stage 11: Write Metadata File

Write team execution metadata:

```json
{
  "status": "planned",
  "summary": "Team planning completed with {N} teammates",
  "artifacts": [
    {
      "type": "plan",
      "path": "specs/{NNN}_{SLUG}/plans/{RR}_implementation-plan.md",
      "summary": "Implementation plan with trade-off analysis"
    }
  ],
  "team_execution": {
    "enabled": true,
    "wave_count": 1,
    "teammates_spawned": {team_size},
    "teammates_completed": {completed_count},
    "teammates_failed": {failed_count},
    "token_usage_multiplier": 5.0,
    "degraded_to_single": false
  },
  "metadata": {
    "session_id": "{session_id}",
    "agent_type": "skill-team-plan",
    "phase_count": {N},
    "estimated_hours": "{X-Y}"
  }
}
```

---

### Stage 12: Git Commit

Commit using targeted staging:

```bash
padded_num=$(printf "%03d" "$task_number")
git add \
  "specs/${padded_num}_${project_name}/plans/" \
  "specs/${padded_num}_${project_name}/.return-meta.json" \
  "specs/TODO.md" \
  "specs/state.json"
git commit -m "task ${task_number}: complete team planning (${team_size} teammates)

Session: ${session_id}
```

---

### Stage 13: Cleanup

Remove marker and temporary files:

```bash
padded_num=$(printf "%03d" "$task_number")
rm -f "specs/${padded_num}_${project_name}/.postflight-pending"
rm -f "specs/${padded_num}_${project_name}/.return-meta.json"
# Keep candidate plans for reference
```

---

### Stage 14: Return Summary

Return brief text summary:

```
Team planning completed for task {N}:
- Spawned {team_size} teammates for parallel plan generation
- Teammate A: Incremental delivery plan ({N} phases)
- Teammate B: Alternative approach ({N} phases)
- Trade-off analysis completed
- Final plan at specs/{NNN}_{SLUG}/plans/{RR}_implementation-plan.md
- Status updated to [PLANNED]
```

---

## Error Handling

### Team Creation Failure
- Fall back to skill-planner
- Mark `degraded_to_single: true`
- Continue with single-agent planning

### Teammate Timeout
- Continue with available results
- Note timeout in synthesis
- Mark result as partial if critical candidate missing

### Git Commit Failure
- Non-blocking: log and continue
- Return success with warning

---

## Return Format

Brief text summary (NOT JSON):

```
Team planning completed for task 412:
- Spawned 2 teammates for parallel plan generation
- Teammate A: Incremental plan (4 phases, 8-12 hours)
- Teammate B: Alternative plan (3 phases, 6-10 hours)
- Selected: Hybrid approach favoring Candidate A structure with B's parallelization
- Final plan at specs/412_task_name/plans/01_implementation-plan.md
- Status updated to [PLANNED]
- Changes committed with session sess_...
```

---

## MUST NOT (Context Protection)

The lead MUST NOT accumulate excessive context during planning or synthesis. Specifically:

1. **Lead MUST NOT read research report content** -- pass `@{research_path}` reference to teammates
2. **Lead MUST NOT read candidate plan files** -- delegate to synthesis-agent (Stage 8)
3. **Lead MUST NOT perform synthesis inline** -- synthesis is done by synthesis-agent
4. **Lead MUST NOT write the unified plan** -- synthesis-agent writes the plan

The postflight phase is LIMITED TO:
- Reading teammate file paths (metadata only, not file content)
- Dispatching synthesis-agent with file paths as @-references
- Receiving compact synthesis summary (~200 words)
- Updating state.json via skill-base.sh functions
- Updating TODO.md status via skill-base.sh functions
- Linking artifacts in state.json
- Git commit
- Cleanup of temp/marker files

**Context budget target**: Lead context growth above baseline should stay under ~1,500 tokens:
- jq state extraction: ~200 tokens
- Delegation context: ~500 tokens
- Teammate handoff metadata (file paths): ~400 tokens
- Synthesis summary returned: ~200 tokens
- Routing overhead: ~200 tokens

Reference: @.claude/context/patterns/context-protective-lead.md

---

## MUST NOT (Postflight Boundary)

After synthesis completes and the plan is written, this skill MUST NOT:

1. **Edit source files** - All planning work is done by teammates
2. **Run build/test commands** - Verification is done by teammates
3. **Analyze task requirements** - Analysis is teammate work
4. **Use research tools** - Research is for teammate use only

Reference: @.claude/context/standards/postflight-tool-restrictions.md
