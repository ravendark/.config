---
name: skill-team-research
description: Orchestrate multi-agent research with wave-based parallel execution. Spawns 2-4 teammates for diverse investigation angles and synthesizes findings.
allowed-tools: Agent, Bash, Edit, Read, Write
# This skill uses Agent tool for team coordination (available when CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
# Synthesis is delegated to synthesis-agent (runs in fresh context, reads all teammate files there)
# Lead context stays under ~1,500 tokens above baseline; synthesis adds only the returned summary (~200 tokens)
---

# Team Research Skill

Multi-agent research with wave-based parallelization. Spawns 2-4 teammates to investigate complementary angles, then delegates synthesis to a named synthesis agent that reads teammate findings in its own fresh context.

**Task-Type-Aware Routing**: Teammates are spawned with task-type-appropriate prompts and tools. Meta tasks focus on .claude/ system patterns; general tasks use web search and codebase exploration.

**IMPORTANT**: This skill requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable. If team creation fails, gracefully degrades to single-agent research via skill-researcher.

## Context References

Reference (load as needed):
- Path: `.claude/context/patterns/team-orchestration.md` - Wave coordination patterns
- Path: `.claude/context/formats/team-metadata-extension.md` - Team result schema
- Path: `.claude/context/formats/return-metadata-file.md` - Base metadata schema
- Path: `.claude/context/reference/team-wave-helpers.md` - Teammate prompt templates and synthesis dispatch template

## Trigger Conditions

This skill activates when:
- `/research N --team` is invoked
- Task exists and status allows research
- Team mode is requested via --team flag

## Input Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `task_number` | integer | Yes | Task to research |
| `focus_prompt` | string | No | Optional focus for research |
| `team_size` | integer | No | Number of teammates (2-4, default 3). Derived from effort flags when not explicitly set: `--fast` = 2, default = 3, `--hard` = 4. Explicit `--team-size N` overrides effort-derived value. |
| `session_id` | string | Yes | Session ID for tracking |
| `model_flag` | string | No | Model override (haiku, sonnet, opus). If set, use instead of default |
| `effort_flag` | string | No | Effort level (fast, hard). Passed as prompt context |

---

## Execution Flow

### Stage 1: Input Validation

Validate required inputs:
- `task_number` - Must exist in state.json
- `team_size` - Derived from effort flags, overridable via `--team-size N`, clamped to [2, 4]

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

# Dynamic team sizing based on effort flags
# Default: 3 (Primary + Alternatives + Critic); --fast: 2; --hard: 4
if [ "$effort_flag" = "fast" ]; then
  team_size=2
elif [ "$effort_flag" = "hard" ]; then
  team_size=4
else
  team_size=3
fi

# Explicit --team-size N override takes precedence over effort-derived value
if [ -n "$user_team_size" ] && [ "$user_team_size" -gt 0 ] 2>/dev/null; then
  team_size="$user_team_size"
fi

# Clamp to valid range [2, 4]
[ "$team_size" -lt 2 ] && team_size=2
[ "$team_size" -gt 4 ] && team_size=4
```

---

### Stage 2: Preflight Status Update

Update task status to "researching" BEFORE spawning teammates.

```bash
bash .claude/scripts/update-task-status.sh preflight "$task_number" research "$session_id"
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
  "skill": "skill-team-research",
  "task_number": ${task_number},
  "operation": "team-research",
  "team_size": ${team_size},
  "reason": "Team research in progress: synthesis dispatch, status update, git commit pending"
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
  # Fall back to skill-researcher
  # ... (see Stage 4a)
fi
```

---

### Stage 4a: Fallback to Single Agent

If team mode is unavailable:

1. Log warning about degradation
2. Invoke `skill-researcher` via Skill tool
3. Pass original parameters
4. Add `degraded_to_single: true` to metadata
5. Continue with postflight

---

### Stage 5a: Calculate Artifact Number

Read `next_artifact_number` from state.json (or fall back to directory scanning for legacy tasks):

```bash
# Read next_artifact_number from state.json
artifact_number=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num) | .next_artifact_number // 1' \
  specs/state.json)

# Fallback for legacy tasks: count existing artifacts
if [ "$artifact_number" = "null" ] || [ -z "$artifact_number" ]; then
  padded_num=$(printf "%03d" "$task_number")
  count=$(ls "specs/${padded_num}_${project_name}/reports/"*[0-9][0-9]*.md 2>/dev/null | wc -l)
  artifact_number=$((count + 1))
fi

run_padded=$(printf "%02d" "$artifact_number")
# run_padded is now the artifact number for this team research run (e.g., "01")
```

**Note**: Team research uses the same artifact number for all teammates and synthesis. The artifact number advances after all teammates and synthesis complete.

---

### Stage 5b: Task Type Routing and Domain Context Injection

Determine task-type-specific configuration and inject domain context into teammate prompts:

```bash
# Route by task type
case "$task_type" in
  "meta")
    # Meta tasks - focus on .claude/ system patterns
    context_refs="@.claude/CLAUDE.md, @.claude/context/index.json"
    available_tools="Read, Grep, Glob"
    ;;
  *)
    # General tasks
    context_refs=""
    available_tools="WebSearch, WebFetch, Read, Grep, Glob"
    ;;
esac

# Determine model for teammates: use model_flag if provided, otherwise default to sonnet (cost-effective for team mode)
teammate_model="${model_flag:-sonnet}"

# Prepare model preference line for prompts (secondary guidance)
model_preference_line="Model preference: Use Claude ${teammate_model^} 4.6 for this analysis."

# Domain context injection: when task_type matches a loaded extension,
# query index.json for domain agent context paths and available MCP tools.
domain_context_section=""
domain_agent_paths=$(jq -r --arg tt "$task_type" '
  .entries[] | select(
    any(.load_when.languages[]?; . == $tt) or
    any(.load_when.task_types[]?; . == $tt)
  ) | .path' .claude/context/index.json 2>/dev/null)

if [ -n "$domain_agent_paths" ]; then
  domain_context_section="## Domain Context

The following domain-specific context files are relevant to this task type (${task_type}).
Read them for domain-specific patterns, tools, and standards:

$(echo "$domain_agent_paths" | while read -r p; do echo "- @.claude/context/$p"; done)

Use domain-specific tools and search strategies described in these files."
fi

# Exploit/Explore mode detection
research_mode="default"
if [ "$EXPLOIT_FLAG" = "true" ]; then
  research_mode="exploit"
elif [ "$EXPLORE_FLAG" = "true" ]; then
  research_mode="explore"
fi
```

---

### Stage 5: Spawn Wave 1 Research Teammates

Create teammate prompts using templates from `.claude/context/reference/team-wave-helpers.md`
(see "Team Research Teammate Prompts" section). Fill in placeholder values from Stage 5b:
`{task_number}`, `{description}`, `{model_preference_line}`, `{domain_context_section}`,
`{run_padded}`, `{NNN}`, `{SLUG}`, `{focus_prompt}`, `{roadmap_path}`.

Apply mode-specific instruction variant based on `research_mode` (default/exploit/explore).

**Wave 1 conditional spawning based on `team_size`** (Critic excluded -- see Stage 6a):
- **Teammate A** (Primary): Always spawned in Wave 1
- **Teammate B** (Alternatives): Spawned in Wave 1 when team_size >= 3
- **Teammate D** (Horizons): Spawned in Wave 1 when team_size >= 4

Wave 1 composition:
- `team_size == 2`: Spawn A only (Critic joins in Wave 2)
- `team_size == 3`: Spawn A + B (Critic joins in Wave 2)
- `team_size == 4`: Spawn A + B + D (Critic joins in Wave 2)

**Spawn teammates using Agent tool** with `model: "${teammate_model}"`.

**IMPORTANT**: Pass the `model` parameter to enforce model selection. The `model_preference_line`
in prompts serves as secondary guidance only.

**Synthesis uses base number without letter**: After all teammates complete, the synthesis report
uses `{run_padded}_{slug}.md` (e.g., `01_team-research.md`).

---

### Stage 6: Wait for Wave 1 Completion

Wait for Wave 1 teammates (A, and optionally B, D) to complete or timeout:

```
Timeout: 30 minutes for Wave 1

While not all Wave 1 teammates complete and not timed out:
  - Check teammate completion status
  - Collect completed results
  - Wait 30 seconds between checks

On timeout:
  - Mark remaining as "timeout"
  - Continue with available results
```

---

### Stage 6a: Spawn Wave 2 Critic

After Wave 1 completes, collect the output file paths from completed Wave 1 teammates and spawn
the Critic. Use the Critic prompt template from `.claude/context/reference/team-wave-helpers.md`
(see "Teammate C — Critic" template). Populate `{wave1_findings}` with the actual paths of
completed Wave 1 output files.

```bash
# Collect Wave 1 output paths
padded_num=$(printf "%03d" "$task_number")
wave1_findings=""

for teammate in a b d; do
  file="specs/${padded_num}_${project_name}/reports/${run_padded}_teammate-${teammate}-findings.md"
  if [ -f "$file" ]; then
    wave1_findings="${wave1_findings}
- ${file}"
  fi
done
```

**Spawn Critic using Agent tool** with `model: "${teammate_model}"`.

Wait for Critic to complete (timeout: 15 minutes for Wave 2).

On timeout: Continue with Wave 1 results only; note missing Critic in synthesis dispatch.

---

### Stage 7: Collect Teammate Handoff Metadata

After both Wave 1 and Wave 2 (Critic) complete, collect only the file paths of completed
teammate finding files. Do NOT read the files themselves — this is delegated to synthesis-agent.

```bash
padded_num=$(printf "%03d" "$task_number")
teammate_paths=()

# Build teammate list based on team_size
teammates=("a" "c")  # A (Primary) and C (Critic) always included
if [ "$team_size" -ge 3 ]; then
  teammates=("a" "b" "c")  # Add B (Alternatives)
fi
if [ "$team_size" -ge 4 ]; then
  teammates=("a" "b" "c" "d")  # Add D (Horizons)
fi

completed_count=0
failed_count=0

for teammate in "${teammates[@]}"; do
  file="specs/${padded_num}_${project_name}/reports/${run_padded}_teammate-${teammate}-findings.md"
  if [ -f "$file" ]; then
    teammate_paths+=("$file")
    completed_count=$((completed_count + 1))
  else
    failed_count=$((failed_count + 1))
  fi
done

# Build @-reference list for synthesis dispatch
teammate_at_refs=""
for path in "${teammate_paths[@]}"; do
  teammate_at_refs="${teammate_at_refs}
- @${path}"
done
```

**Lead context growth from this stage**: ~100 tokens per teammate (file paths only, no content).

---

### Stage 8: Dispatch Synthesis Agent

Dispatch the synthesis agent with teammate file paths as @-references. The synthesis agent reads
all finding files in its own fresh context. See dispatch template in
`.claude/context/reference/team-wave-helpers.md` (see "Synthesis Agent Dispatch" section).

Determine prior artifacts for the task (any prior reports or plans at
`specs/{NNN}_{SLUG}/reports/` or `specs/{NNN}_{SLUG}/plans/` from previous rounds):

```bash
output_path="specs/${padded_num}_${project_name}/reports/${run_padded}_team-research.md"
mkdir -p "specs/${padded_num}_${project_name}/reports/"
```

Dispatch:
```
Agent(
  subagent_type: "synthesis-agent",
  prompt: "Synthesize research for task {task_number}: {description}

## Teammate Findings

Read each of the following teammate finding files:
{teammate_at_refs}

## Context

Task description: {description}
Focus prompt: {focus_prompt}
Research mode: {research_mode}
Team size: {team_size}

## Additional Context

Read for task context:
- @specs/TODO.md
- @specs/ROADMAP.md (read if it exists; skip if not)

## Output

Write the unified research report to:
{output_path}

Follow the format in @.claude/context/formats/report-format.md

## Return

After writing the report, return a compact summary (under 200 words) with:
- Top 3 unified findings
- Conflicts resolved (count and brief description)
- Gaps identified (count and brief description)
- Overall confidence level (high/medium/low)
- Full path to the written report",
  model: "${teammate_model}",
  timeout: 1200
)
```

**On synthesis failure**: See Error Handling section below.

---

### Stage 9: Record Synthesis Result

Receive the compact summary (under 200 words) from the synthesis agent and extract:

- `artifact_path`: The output path reported by the synthesis agent
- `synthesis_summary`: The compact text summary
- `confidence`: Overall confidence level (high/medium/low)

Store these for postflight use. The lead does NOT read the unified report file.

**Lead context growth from synthesis**: ~200 tokens (synthesis summary only).

On synthesis failure (agent returned error or did not write the report):
- Set `artifact_path` to the most complete raw teammate finding (prefer Teammate A)
- Set `synthesis_failed = true` for postflight metadata
- Continue to postflight with `partial` status

---

### Stage 10: Update Status (Postflight)

Update task status to "researched" using skill-base.sh functions:

```bash
source .claude/scripts/skill-base.sh

# Step 1: Update status in state.json and TODO.md
skill_postflight_update "$task_number" "research" "$session_id" "researched"

# Step 2: Increment next_artifact_number (team research advances the sequence)
skill_increment_artifact_number "$task_number"

# Step 3: Link synthesis artifact in state.json and TODO.md
artifact_summary="Team research with ${team_size} teammates"
skill_link_artifacts "$task_number" "$artifact_path" "research" "$artifact_summary" "'**Research**'" "'**Plan**'"
```

**Note**: Team research (like single-agent research) is the only operation that increments
`next_artifact_number`. Team plan and team implement use `(current - 1)` to stay in the same round.

---

### Stage 11: Write Metadata File

Write team execution metadata:

```json
{
  "status": "researched",
  "summary": "Team research completed with {N} teammates",
  "artifacts": [
    {
      "type": "research",
      "path": "specs/{NNN}_{SLUG}/reports/{RR}_team-research.md",
      "summary": "Synthesized research from {team_size} teammates"
    }
  ],
  "team_execution": {
    "enabled": true,
    "wave_count": 2,
    "teammates_spawned": {team_size},
    "teammates_completed": {completed_count},
    "teammates_failed": {failed_count},
    "token_usage_multiplier": 5.0,
    "degraded_to_single": false
  },
  "synthesis": {
    "agent": "synthesis-agent",
    "confidence": "{confidence}",
    "summary": "{synthesis_summary}"
  },
  "metadata": {
    "session_id": "{session_id}",
    "agent_type": "skill-team-research"
  }
}
```

---

### Stage 12: Git Commit

Commit using targeted staging (prevents race conditions with concurrent agents):

```bash
padded_num=$(printf "%03d" "$task_number")
git add \
  "specs/${padded_num}_${project_name}/reports/" \
  "specs/${padded_num}_${project_name}/.return-meta.json" \
  "specs/TODO.md" \
  "specs/state.json"
git commit -m "task ${task_number}: complete team research (${team_size} teammates)

Session: ${session_id}
```

**Note**: Use targeted staging, NOT `git add -A`. See `.claude/context/standards/git-staging-scope.md`.

---

### Stage 13: Cleanup

Remove marker and temporary files:

```bash
source .claude/scripts/skill-base.sh
skill_cleanup "$padded_num" "$project_name"
# Keep teammate findings files for reference
```

---

### Stage 14: Return Summary

Return brief text summary:

```
Team research completed for task {N}:
- Spawned {team_size} teammates for parallel investigation
- Teammate A: Primary approach findings (high confidence)
- Teammate B: Alternative patterns identified (medium confidence)
- {N} conflicts found and resolved
- Synthesized report at specs/{NNN}_{SLUG}/reports/{RR}_team-research.md
- Status updated to [RESEARCHED]
```

---

## Error Handling

### Team Creation Failure
- Fall back to skill-researcher
- Mark `degraded_to_single: true`
- Continue with single-agent research

### Teammate Timeout
- Continue with available results
- Note timeout in synthesis dispatch (synthesis agent handles the missing file gracefully)
- Mark result as partial if critical teammate missing (Teammate A)

### Synthesis Failure
- Preserve raw teammate findings (they are already on disk)
- Set artifact_path to most complete raw finding (prefer Teammate A)
- Mark status as partial
- Log: "Synthesis failed: {reason}. Raw teammate findings preserved."

### Git Commit Failure
- Non-blocking: log and continue
- Return success with warning

---

## Return Format

Brief text summary (NOT JSON):

```
Team research completed for task 412:
- Spawned 3 teammates for parallel investigation
- Teammate A: Implementation patterns (high confidence)
- Teammate B: Prior art analysis (medium confidence)
- Teammate C: Risk analysis (high confidence)
- 1 conflict resolved (approach preference)
- Synthesized report at specs/412_task_name/reports/01_team-research.md
- Status updated to [RESEARCHED]
- Changes committed with session sess_...
```

---

## MUST NOT (Context Protection)

The lead MUST NOT accumulate excessive context during synthesis or postflight. Specifically:

1. **Lead MUST NOT read teammate finding files** — delegate to synthesis-agent (Stage 8)
2. **Lead MUST NOT perform synthesis analysis inline** — synthesis is done by synthesis-agent
3. **Lead MUST NOT write the unified report** — synthesis-agent writes the report
4. **Lead MUST NOT use WebSearch/WebFetch** — research tools are for teammate use only
5. **Lead MUST NOT edit source files** — all research work is done by teammates
6. **Lead MUST NOT run build/test commands** — verification is done by teammates
7. **Lead MUST NOT analyze or grep source** — analysis is teammate work

The postflight phase is LIMITED TO:
- Reading teammate file paths (metadata only, not file content)
- Dispatching synthesis-agent with file paths as @-references
- Receiving compact synthesis summary (~200 words)
- Updating state.json via skill-base.sh functions
- Updating TODO.md status via skill-base.sh functions
- Linking artifacts in state.json
- Git commit
- Cleanup of temp/marker files

**Context budget target**: Lead context growth above baseline should stay under 1,500 tokens
for the full operation:
- jq state extraction: ~200 tokens
- Delegation context: ~500 tokens
- Teammate handoff metadata (file paths): ~400 tokens
- Synthesis summary returned: ~200 tokens
- Routing overhead: ~200 tokens

Reference: @.claude/context/patterns/context-protective-lead.md
Reference: @.claude/context/standards/postflight-tool-restrictions.md
