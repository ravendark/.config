---
name: skill-team-research
description: Orchestrate multi-agent research with wave-based parallel execution. Spawns 2-4 teammates for diverse investigation angles and synthesizes findings.
allowed-tools: Agent, Bash, Edit, Read, Write
# This skill uses Agent tool for team coordination (available when CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
# Context loaded by lead during synthesis:
#   - .claude/context/patterns/team-orchestration.md
#   - .claude/context/formats/team-metadata-extension.md
#   - .claude/context/reference/team-wave-helpers.md
---

# Team Research Skill

Multi-agent research with wave-based parallelization. Spawns 2-4 teammates to investigate complementary angles, then synthesizes findings into a unified report.

**Task-Type-Aware Routing**: Teammates are spawned with task-type-appropriate prompts and tools. Meta tasks focus on .claude/ system patterns; general tasks use web search and codebase exploration.

**IMPORTANT**: This skill requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable. If team creation fails, gracefully degrades to single-agent research via skill-researcher.

## Context References

Reference (load as needed during synthesis):
- Path: `.claude/context/patterns/team-orchestration.md` - Wave coordination patterns
- Path: `.claude/context/formats/team-metadata-extension.md` - Team result schema
- Path: `.claude/context/formats/return-metadata-file.md` - Base metadata schema
- Path: `.claude/context/reference/team-wave-helpers.md` - Reusable wave patterns

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
  "reason": "Team research in progress: synthesis, status update, git commit pending"
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
# This ensures team research teammates get the same domain knowledge as
# single-agent research (which uses the domain-specific research agent).
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
# These flags shape teammate prompt generation (see Stage 5 teammate prompts)
research_mode="default"
if [ "$EXPLOIT_FLAG" = "true" ]; then
  research_mode="exploit"
elif [ "$EXPLORE_FLAG" = "true" ]; then
  research_mode="explore"
fi
```

---

### Stage 5: Spawn Wave 1 Research Teammates

Create teammate prompts and spawn Wave 1 (non-Critic teammates). The Critic spawns in Wave 2 after reading Wave 1 findings. Pass `artifact_number` and `teammate_letter` to each teammate.

Each teammate prompt should include `{domain_context_section}` (from Stage 5b) when non-empty.

**Delegation context for teammates**:
```json
{
  "artifact_number": "{run_padded}",
  "teammate_letter": "a",
  "artifact_pattern": "{NN}_teammate-{letter}-findings.md",
  "roadmap_path": "specs/ROADMAP.md"
}
```

**Teammate A - Primary Angle**:
```
Research task {task_number}: {description}

{model_preference_line}

Artifact number: {run_padded}
Teammate letter: a

Focus on implementation approaches and patterns.
Challenge assumptions and provide specific examples.
Consider {focus_prompt} if provided.

Output your findings to:
specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-a-findings.md

Format: Markdown with clear sections for:
- Key Findings
- Recommended Approach
- Evidence/Examples
- Confidence Level (high/medium/low)
```

**Teammate B - Alternative Approaches** (spawn when `team_size >= 2`, i.e., always):
```
Research task {task_number}: {description}

{model_preference_line}

Artifact number: {run_padded}
Teammate letter: b

Focus on alternative patterns and prior art.
Look for existing solutions we could adapt.
Do NOT duplicate Teammate A's focus on primary approaches.

Output your findings to:
specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-b-findings.md

Format: Same as Teammate A
```

**Teammate C - Critic (Wave 2 -- spawned AFTER Wave 1 completes)**:

The Critic is NOT spawned in Wave 1. Instead, after all Wave 1 teammates complete (Stage 6a), the Critic is spawned with access to their findings. This allows the Critic to provide informed, targeted critique rather than generic skepticism.

See **Stage 6a** below for the Critic spawn logic and prompt.

**Teammate D - Horizons** (spawn when `team_size >= 4`):
```
Research task {task_number}: {description}

{model_preference_line}

Artifact number: {run_padded}
Teammate letter: d

You are the Horizons researcher. Your job is to think about long-term alignment and strategic direction.

Read the project roadmap at {roadmap_path} (from delegation context) if it exists.
If the roadmap file does not exist, contribute general strategic thinking about project direction.

Focus on:
- Does the proposed approach align with the project's long-term goals and priorities?
- Are there opportunities to advance adjacent roadmap items simultaneously?
- Could the task be scoped differently to better serve the project trajectory?
- What creative or unconventional approaches might better serve the long-term vision?
- What strategic challenges remain that this task could help address?

Think outside the box. Challenge conventional approaches where a better path exists.

Output your findings to:
specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-d-findings.md

Format: Same as Teammate A
```

---

**Spawn teammates using Agent tool**.

**Wave 1 conditional spawning based on `team_size`** (Critic excluded -- see Stage 6a):
- **Teammate A** (Primary): Always spawned in Wave 1
- **Teammate B** (Alternatives): Spawned in Wave 1 when team_size >= 3
- **Teammate D** (Horizons): Spawned in Wave 1 when team_size >= 4

Wave 1 composition:
- `team_size == 2`: Spawn A only (Critic joins in Wave 2)
- `team_size == 3`: Spawn A + B (Critic joins in Wave 2)
- `team_size == 4`: Spawn A + B + D (Critic joins in Wave 2)

**IMPORTANT**: Pass the `model` parameter to enforce model selection:
- Use `model: "${teammate_model}"` (from Stage 5b: model_flag if provided, otherwise "sonnet" as default)

The `model_preference_line` in prompts serves as secondary guidance only. The `model` parameter on Agent tool is the enforced selection.

**Synthesis uses base number without letter**: After all teammates complete, the synthesis report uses `{run_padded}_{slug}.md` (e.g., `01_team-research.md`).

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

After Wave 1 completes, collect the output file paths from completed Wave 1 teammates and spawn the Critic with access to their findings.

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

**Teammate C - Critic (Wave 2)**:
```
Research task {task_number}: {description}

{model_preference_line}

{domain_context_section}

Artifact number: {run_padded}
Teammate letter: c

You are the Critic. You run in Wave 2 -- the other teammates have already completed their research.

## Wave 1 Teammate Findings

Read the following teammate findings before critiquing:
{wave1_findings}

Read each file above, then provide your critique.

## Your Focus

Based on your reading of the teammate findings, identify:
- What assumptions haven't been validated by the teammates?
- Where do the teammates disagree, and who has stronger evidence?
- Are there known limitations in the proposed approaches that teammates missed?
- Is the task scope complete, or are there important aspects being overlooked?
- What questions should be asked but aren't being asked?
- Which teammate's findings are strongest/weakest, and why?

Do NOT duplicate risk analysis (implementation risks). Focus on research quality and completeness.

Output your findings to:
specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-c-findings.md

Format: Markdown with clear sections for:
- Key Findings
- Recommended Approach
- Evidence/Examples
- Confidence Level (high/medium/low)
```

**Spawn Critic using Agent tool** with `model: "${teammate_model}"`.

Wait for Critic to complete (timeout: 15 minutes for Wave 2).

On timeout: Continue with Wave 1 results only; note missing Critic in synthesis.

---

### Stage 7: Collect All Teammate Results

After both Wave 1 and Wave 2 (Critic) complete, read each teammate's output file using run-scoped paths:

```bash
teammate_results=[]
padded_num=$(printf "%03d" "$task_number")

# Build teammate list based on team_size
teammates=("a" "c")  # A (Primary) and C (Critic) always present
if [ "$team_size" -ge 3 ]; then
  teammates=("a" "b" "c")  # Add B (Alternatives)
fi
if [ "$team_size" -ge 4 ]; then
  teammates=("a" "b" "c" "d")  # Add D (Horizons)
fi

for teammate in "${teammates[@]}"; do
  # Use run-scoped path
  file="specs/${padded_num}_${project_name}/reports/${run_padded}_teammate-${teammate}-findings.md"
  if [ -f "$file" ]; then
    # Parse findings
    # Extract confidence level
    # Check for conflicts with other teammates
    teammate_results+=("...")
  fi
done
```

---

### Stage 8: Synthesize Findings

Lead synthesizes all teammate results:

1. **Extract key findings** from each teammate
2. **Detect conflicts** between findings
3. **Resolve conflicts** with evidence-based judgment
4. **Identify gaps** in coverage
5. **Incorporate Wave 2 Critic findings** as targeted critique of other teammates' work

**Conflict Resolution**:
- Compare findings across teammates
- Log conflicts found
- Make judgment call based on evidence strength
- Document resolution reasoning

---

### Stage 9: Create Unified Report

Write synthesized report:

```markdown
# Research Report: Task #{N}

**Task**: {title}
**Date**: {ISO_DATE}
**Mode**: Team Research ({team_size} teammates)

## Summary

{Synthesized summary of findings}

## Key Findings

### Primary Approach (from Teammate A)
{Findings}

### Alternative Approaches (from Teammate B)
{Findings}

### Gaps and Shortcomings (from Critic)
{Findings}

### Strategic Horizons (from Horizons)
{Findings}

## Synthesis

### Conflicts Resolved
{List of conflicts and how they were resolved}

### Gaps Identified
{List of any remaining gaps}

### Recommendations
{Synthesized recommendations}

## Teammate Contributions

| Teammate | Angle | Status | Confidence |
|----------|-------|--------|------------|
| A | Primary | completed | high |
| B | Alternatives | completed | medium |
| C | Critic | completed | high |
| D | Horizons | completed | medium |

## References

{Sources cited by teammates}
```

Output to: `specs/{NNN}_{SLUG}/reports/{RR}_team-research.md`

---

### Stage 10: Update Status (Postflight)

Update task status to "researched":

Step 1: Run centralized script for state.json and TODO.md status update:
```bash
bash .claude/scripts/update-task-status.sh postflight "$task_number" research "$session_id"
```

Step 2: Increment `next_artifact_number` (team research advances the sequence):
```bash
jq '(.active_projects[] | select(.project_number == '$task_number')).next_artifact_number =
    (((.active_projects[] | select(.project_number == '$task_number')).next_artifact_number // 1) + 1)' \
  specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
```

**Note**: Team research (like single-agent research) is the only operation that increments `next_artifact_number`. Team plan and team implement use `(current - 1)` to stay in the same "round".

**Link artifact in state.json**:
```bash
padded_num=$(printf "%03d" "$task_number")
jq --arg path "specs/${padded_num}_${project_name}/reports/${run_padded}_team-research.md" \
   --arg type "research" \
   --arg summary "Team research with ${team_size} teammates" \
  '(.active_projects[] | select(.project_number == '$task_number')).artifacts += [{"path": $path, "type": $type, "summary": $summary}]' \
  specs/state.json > specs/tmp/state.json && mv specs/tmp/state.json specs/state.json
```

**Link artifact in TODO.md**: Use the `link-artifact-todo.sh` script (REQUIRED -- do NOT manually edit artifact links in TODO.md):

```bash
bash .claude/scripts/link-artifact-todo.sh $task_number '**Research**' '**Plan**' "$artifact_path"
```

The script produces bracket-only `[path]` format. Never use markdown `[name](path)` format for artifact links. If the script exits non-zero, log a warning but continue (linking errors are non-blocking).

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
  "teammate_results": [...],
  "synthesis": {
    "conflicts_found": {N},
    "conflicts_resolved": {N},
    "gaps_identified": {N},
    "wave_2_triggered": false
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
padded_num=$(printf "%03d" "$task_number")
rm -f "specs/${padded_num}_${project_name}/.postflight-pending"
rm -f "specs/${padded_num}_${project_name}/.return-meta.json"
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
- Note timeout in synthesis
- Mark result as partial if critical teammate missing

### Synthesis Failure
- Preserve raw teammate findings
- Mark status as partial
- Provide raw findings to user

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

## MUST NOT (Postflight Boundary)

After teammates complete and findings are synthesized, this skill MUST NOT:

1. **Edit source files** - All research work is done by teammates
2. **Run build/test commands** - Verification is done by teammates
3. **Use WebSearch/WebFetch** - Research tools are for teammate use only
4. **Analyze or grep source** - Analysis is teammate work
5. **Write reports** - Artifact creation is done during synthesis, not postflight

The postflight phase is LIMITED TO:
- Reading teammate metadata files
- Updating state.json via jq
- Updating TODO.md status marker via Edit
- Linking artifacts in state.json
- Git commit
- Cleanup of temp/marker files

Reference: @.claude/context/standards/postflight-tool-restrictions.md
