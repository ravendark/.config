# Team Wave Helpers

Reusable patterns for wave-based team coordination.

## Overview

This file contains reference patterns for implementing team skills. Copy and adapt these patterns rather than importing directly.

## Artifact Numbering Helpers

### Unified Artifact Numbering

All artifacts (reports, plans, summaries) share a single sequence number per task within a "round" of work. Research advances the sequence; plan and implement reuse the current number.

**Read Artifact Number for Research (advances sequence)**:
```bash
# Read next_artifact_number from state.json
artifact_number=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num) | .next_artifact_number // 1' \
  specs/state.json)

# Fallback for legacy tasks
if [ "$artifact_number" = "null" ] || [ -z "$artifact_number" ]; then
  padded_num=$(printf "%03d" "$task_number")
  count=$(ls "specs/${padded_num}_${SLUG}/reports/"*[0-9][0-9]*.md 2>/dev/null | wc -l)
  artifact_number=$((count + 1))
fi

run_padded=$(printf "%02d" "$artifact_number")
# After completion, increment: next_artifact_number = artifact_number + 1
```

**Read Artifact Number for Plan/Implement (stays in same round)**:
```bash
# Read next_artifact_number and use (current - 1)
next_num=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num) | .next_artifact_number // 1' \
  specs/state.json)

# Plan/implement use (current - 1) to stay in same round
if [ "$next_num" -le 1 ]; then
  artifact_number=1
else
  artifact_number=$((next_num - 1))
fi

run_padded=$(printf "%02d" "$artifact_number")
# Do NOT increment next_artifact_number after completion
```

### Team Mode Artifact Naming

**Teammate Artifacts**: `{NN}_teammate-{letter}-findings.md`
- Example: `01_teammate-a-findings.md`, `01_teammate-b-findings.md`

**Synthesis Artifacts**: `{NN}_{slug}.md` (base number, no letter)
- Example: `01_team-research.md`, `01_implementation-plan.md`

**Key Principle**: All artifacts from the same research round share the same base number. Letter suffixes distinguish parallel work within a round.

---

## Wave Spawning Pattern

### Spawn Research Wave

Spawn 2-4 teammates for parallel research. First, calculate the artifact number using unified numbering:

```bash
# Read next_artifact_number from state.json (research advances the sequence)
artifact_number=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num) | .next_artifact_number // 1' \
  specs/state.json)

# Fallback for legacy tasks
if [ "$artifact_number" = "null" ] || [ -z "$artifact_number" ]; then
  padded_num=$(printf "%03d" "$task_number")
  count=$(ls "specs/${padded_num}_${SLUG}/reports/"*[0-9][0-9]*.md 2>/dev/null | wc -l)
  artifact_number=$((count + 1))
fi

run_padded=$(printf "%02d" "$artifact_number")
```

Then spawn teammates with run-scoped output paths. **Pass the `model` parameter** to enforce model selection:

```
# Research Wave Spawning (run {RR})
Wave 1 teammates:
1. Primary Angle (required)
   - Name: "{Task}ResearcherA"
   - Model: "sonnet"
   - Prompt: "Research {task} focusing on implementation approaches.
     Challenge assumptions. Provide specific examples.
     Output to: specs/{NNN}_{SLUG}/reports/{RR}_teammate-a-findings.md"

2. Alternative Approaches (required)
   - Name: "{Task}ResearcherB"
   - Prompt: "Research {task} focusing on alternative patterns and prior art.
     Look for existing solutions we could adapt.
     Output to: specs/{NNN}_{SLUG}/reports/{RR}_teammate-b-findings.md"

3. Risk Analysis (optional, size >= 3)
   - Name: "{Task}ResearcherC"
   - Prompt: "Research {task} focusing on risks, blockers, and edge cases.
     Identify what could go wrong.
     Output to: specs/{NNN}_{SLUG}/reports/{RR}_teammate-c-findings.md"

4. Devil's Advocate (optional, size >= 4)
   - Name: "{Task}ResearcherD"
   - Prompt: "Challenge findings from other teammates.
     Look for gaps, inconsistencies, and missed alternatives.
     Output to: specs/{NNN}_{SLUG}/reports/{RR}_teammate-d-findings.md"
```

### Spawn Planning Wave

Spawn teammates for parallel plan generation. First, calculate the artifact number using unified numbering:

```bash
# Read next_artifact_number and use (current - 1) since plan stays in same round
next_num=$(jq -r --argjson num "$task_number" \
  '.active_projects[] | select(.project_number == $num) | .next_artifact_number // 1' \
  specs/state.json)

# Plan uses (current - 1) to stay in same round as research
if [ "$next_num" -le 1 ]; then
  artifact_number=1
else
  artifact_number=$((next_num - 1))
fi

# Fallback for legacy tasks
if [ "$next_num" = "null" ] || [ -z "$next_num" ]; then
  padded_num=$(printf "%03d" "$task_number")
  count=$(ls "specs/${padded_num}_${SLUG}/plans/"*[0-9][0-9]*.md 2>/dev/null | wc -l)
  artifact_number=$((count + 1))
fi

run_padded=$(printf "%02d" "$artifact_number")
```

Then spawn teammates with run-scoped output paths:

```
# Planning Wave Spawning (run {RR})
Wave 1 teammates:
1. Plan Version A (required)
   - Name: "{Task}PlannerA"
   - Model: "sonnet"
   - Prompt: "Create a phased implementation plan for {task}.
     Focus on incremental delivery with verification at each phase.
     Output to: specs/{NNN}_{SLUG}/plans/{RR}_candidate-a.md"

2. Plan Version B (required)
   - Name: "{Task}PlannerB"
   - Prompt: "Create an alternative implementation plan for {task}.
     Consider different phase boundaries or ordering.
     Output to: specs/{NNN}_{SLUG}/plans/{RR}_candidate-b.md"

3. Risk/Dependency Analysis (optional, size >= 3)
   - Name: "{Task}PlannerC"
   - Prompt: "Analyze dependencies and risks for implementing {task}.
     Identify which phases can be parallelized vs sequential.
     Output to: specs/{NNN}_{SLUG}/plans/{RR}_risk-analysis.md"
```

### Spawn Implementation Wave

Spawn teammates for parallel phase execution:

```
# Implementation Wave Spawning
For each independent phase group:
1. Phase Implementer (per independent phase)
   - Name: "{Task}Phase{P}Impl"
   - Model: "sonnet"
   - Prompt: "Implement phase {P} of the plan for {task}.
     Follow the steps in the implementation plan.
     Update phase status markers as you complete.
     Write results to: specs/{NNN}_{SLUG}/phases/{RR}_phase-{P}-results.md"

2. Debugger (spawned on error)
   - Name: "{Task}Debugger"
   - Model: "sonnet"
   - Prompt: "Analyze the error in {task} implementation.
     Error: {error_details}
     Generate hypothesis and create debug report at:
     specs/{NNN}_{SLUG}/debug/{RR}_phase-{P}-debug.md"
```

## Wait and Collect Pattern

### Wait for Wave Completion

```
# Wait for all teammates in wave
For each teammate in current wave:
  1. Check if teammate has notified completion
  2. If not, wait with timeout (30 min per wave)
  3. On timeout: mark as timed out, continue with available

Collect results:
  1. Read each teammate's output file
  2. Parse status (completed/partial/failed)
  3. Store in teammate_results array
```

### Collect Teammate Results

Use run-scoped paths to collect teammate findings:

```bash
# Pattern: Collect results from teammate files (run-scoped)
padded_num=$(printf "%03d" "$task_number")
teammate_files=(
  "specs/${padded_num}_${SLUG}/reports/${run_padded}_teammate-a-findings.md"
  "specs/${padded_num}_${SLUG}/reports/${run_padded}_teammate-b-findings.md"
  # ... add more as needed based on team_size
)

for file in "${teammate_files[@]}"; do
  if [ -f "$file" ]; then
    # Parse findings from file
    # Add to teammate_results
  else
    # Mark as failed/missing
  fi
done
```

## Synthesis Pattern

### Lead Synthesis Loop

```
# Synthesis procedure
1. Initialize synthesis object
   - conflicts_found: 0
   - conflicts_resolved: 0
   - gaps_identified: 0

2. For each teammate result:
   a. Extract key findings
   b. Compare with other teammates for conflicts
   c. Log any conflicts found

3. Conflict resolution:
   For each conflict:
   a. Evaluate evidence strength
   b. Make judgment call
   c. Document resolution reason
   d. Increment conflicts_resolved

4. Gap analysis:
   a. Check if any expected angle missing
   b. Check for contradictions without resolution
   c. Decide if Wave 2 needed (not implemented in v1)

5. Generate unified output:
   a. Merge non-conflicting findings
   b. Include resolved conflicts with reasoning
   c. Note any remaining gaps
```

### Conflict Detection

```
# Pattern: Detect conflicts between findings
conflicts = []

for each finding_a in teammate_a.findings:
  for each finding_b in teammate_b.findings:
    if contradicts(finding_a, finding_b):
      conflicts.append({
        "teammate_a": "ResearcherA",
        "finding_a": finding_a,
        "teammate_b": "ResearcherB",
        "finding_b": finding_b
      })
```

## Graceful Degradation Pattern

### Fallback to Single Agent

```
# Pattern: Graceful degradation
try:
  spawn_teammates()
except TeamCreationFailed:
  log_warning("Team mode unavailable, falling back to single agent")

  # Execute single-agent version
  result = execute_single_agent_workflow()

  # Mark as degraded in metadata
  result.team_execution = {
    "enabled": true,
    "degraded_to_single": true,
    "degradation_reason": "Teams feature unavailable"
  }

  return result
```

### Partial Teammate Failure

```
# Pattern: Handle partial teammate failure
available_results = []
failed_teammates = []

for teammate in wave:
  if teammate.status == "completed":
    available_results.append(teammate.result)
  else:
    failed_teammates.append(teammate.name)

if len(available_results) >= 1:
  # Synthesize from available
  synthesis = synthesize(available_results)
  synthesis.gaps_identified += len(failed_teammates)
else:
  # All failed, degrade to single
  return fallback_to_single_agent()
```

## Timeout Handling Pattern

```
# Pattern: Wave timeout handling
WAVE_TIMEOUT = 1800  # 30 minutes per wave

start_time = now()
completed = []

while len(completed) < len(wave) and (now() - start_time) < WAVE_TIMEOUT:
  for teammate in wave:
    if teammate.is_complete() and teammate not in completed:
      completed.append(teammate)
  sleep(30)  # Poll every 30 seconds

# After timeout, collect what we have
for teammate in wave:
  if teammate not in completed:
    teammate.status = "timeout"
    log_warning(f"{teammate.name} timed out")
```

## Language Routing Pattern

Team skills route teammates based on the task's `language` field:

### Language Routing Lookup

```
# Pattern: Route by task language
language_config = {
  "meta": {
    "research_agent": "general-research-agent",
    "implementation_agent": "general-implementation-agent",
    "default_model": "sonnet",
    "context_references": [
      "@.opencode/CLAUDE.md",
      "@.opencode/context/index.json"
    ],
    "blocked_tools": [],
    "research_tools": ["Read", "Grep", "Glob"],
    "implementation_tools": ["Write", "Edit"],
    "verification": "File creation and consistency checks"
  },
  "general": {
    "research_agent": "general-research-agent",
    "implementation_agent": "general-implementation-agent",
    "default_model": "sonnet",
    "context_references": [],
    "blocked_tools": [],
    "research_tools": ["WebSearch", "WebFetch", "Read"],
    "implementation_tools": ["Read", "Write", "Edit", "Bash"],
    "verification": "Project-specific build/test commands"
  }
}

# Model Selection (ENFORCED via Agent tool parameter)
#
# default_model specifies the Claude model for teammates:
# - "sonnet": Balanced model (Sonnet 4.6), used for most tasks
#
# ENFORCEMENT:
# - Pass `model: $default_model` when spawning teammates via Agent tool
# - The model preference in prompts is secondary guidance only
# - Model selection is enforced at the tool level
```

## Related Files

- `.opencode/context/patterns/team-orchestration.md` - Overall coordination
- `.opencode/context/formats/team-metadata-extension.md` - Result schema
- `.opencode/skills/skill-team-*/SKILL.md` - Skill implementations

---

## Team Research Teammate Prompts

Full prompt templates for `skill-team-research` teammates. The skill references these templates and fills in the placeholder values. The templates include mode-specific instruction variants (default/exploit/explore).

### Placeholder Reference

| Placeholder | Source | Description |
|-------------|--------|-------------|
| `{task_number}` | state.json | Unpadded task number |
| `{description}` | state.json | Task description text |
| `{model_preference_line}` | Stage 5b | "Model preference: Use Claude {model^} 4.6 for this analysis." |
| `{domain_context_section}` | Stage 5b | Domain context block (empty for general tasks) |
| `{run_padded}` | Stage 5a | Zero-padded artifact number (e.g., "01") |
| `{NNN}` | Stage 1 | Zero-padded task directory number |
| `{SLUG}` | Stage 1 | Task slug (project_name from state.json) |
| `{focus_prompt}` | Invocation | User-provided focus (may be empty) |
| `{wave1_findings}` | Stage 6a | Newline-separated list of Wave 1 output file paths |
| `{roadmap_path}` | Stage 5 | "specs/ROADMAP.md" (static value) |

### Teammate A — Primary Angle

```
Research task {task_number}: {description}

{model_preference_line}

{domain_context_section}

Artifact number: {run_padded}
Teammate letter: a

{mode-specific instructions for Teammate A:}
  default: "Focus on implementation approaches and patterns."
  exploit: "Deep-dive into the most promising approach. Decompose it into sub-problems and
    analyze each thoroughly. Validate assumptions with concrete evidence."
  explore: "Breadth-first survey of all possible approaches. Cast a wide net for solutions.
    Prioritize diversity of ideas over depth."

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

### Teammate B — Alternative Approaches (spawn when `team_size >= 3`)

```
Research task {task_number}: {description}

{model_preference_line}

{domain_context_section}

Artifact number: {run_padded}
Teammate letter: b

{mode-specific instructions for Teammate B:}
  default: "Focus on alternative patterns and prior art. Look for existing solutions we
    could adapt."
  exploit: "Validate and stress-test the primary approach. Find edge cases, failure modes,
    and limitations. Try to break it."
  explore: "Investigate unconventional or creative alternatives. Look for solutions from
    adjacent domains that could be adapted."

Do NOT duplicate Teammate A's focus.

Output your findings to:
specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-b-findings.md

Format: Same as Teammate A
```

### Teammate C — Critic (Wave 2, spawned AFTER Wave 1 completes)

The Critic is NOT spawned in Wave 1. After all Wave 1 teammates complete (Stage 6a), the Critic
is spawned with access to their findings. The `{wave1_findings}` placeholder is populated from
the actual output paths of completed Wave 1 teammates.

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

### Teammate D — Horizons (spawn when `team_size >= 4`)

```
Research task {task_number}: {description}

{model_preference_line}

{domain_context_section}

Artifact number: {run_padded}
Teammate letter: d

You are the Horizons researcher.

{mode-specific instructions for Teammate D:}
  default: "Think about long-term alignment and strategic direction."
  exploit: "Assess implementation feasibility of the primary approach. What infrastructure
    exists? What's missing? What would make this approach succeed or fail at scale?"
  explore: "Identify approaches we haven't considered. Look at how other ecosystems and
    communities solve similar problems. Think unconventionally."

Read the project roadmap at {roadmap_path} if it exists.
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

## Synthesis Agent Dispatch

Template for dispatching the `synthesis-agent` from the lead after all teammates (including the
Critic) have completed. The lead passes teammate artifact paths as @-references; the synthesis
agent reads them in its own fresh context.

### Dispatch Prompt Template

```
Synthesize research for task {task_number}: {description}

## Teammate Findings

Read each of the following teammate finding files:
{teammate_finding_paths_as_at_refs}

Example format:
- @specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-a-findings.md
- @specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-b-findings.md
- @specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-c-findings.md
- @specs/{NNN}_{SLUG}/reports/{run_padded}_teammate-d-findings.md  (if spawned)

## Context

Task description: {description}
Focus prompt: {focus_prompt} (may be empty)
Research mode: {research_mode} (default/exploit/explore)
Team size: {team_size}

## Additional Context

Read for task context:
- @specs/TODO.md (find task {task_number} entry for context)
- @specs/ROADMAP.md (if exists, check for relevant roadmap items)

{prior_artifacts_section}
(If prior reports or plans exist for this task, list them here as @-references)

## Output

Write the unified research report to:
{output_path}

Follow the format in @.opencode/context/formats/report-format.md

## Return

After writing the report, return a compact summary (under 200 words) with:
- Top 3 unified findings
- Conflicts resolved (count and brief description)
- Gaps identified (count and brief description)
- Overall confidence level (high/medium/low)
- Full path to the written report
```

### Lead Dispatch Call (pseudocode)

```
Agent(
  subagent_type: "synthesis-agent",
  prompt: [populated dispatch prompt from template above],
  model: "${teammate_model}",    # same model as teammates (sonnet by default)
  timeout: 1200                  # 20 minutes for synthesis
)
```

### Expected Return Format

The synthesis agent returns text (not JSON) with this structure:

```
Synthesis complete for task {N}.

Top findings:
1. {Finding 1}
2. {Finding 2}
3. {Finding 3}

Conflicts resolved: {N} ({brief description or "none"})
Gaps identified: {N} ({brief description or "none"})
Overall confidence: {high/medium/low}
Report written to: {output_path}
```

The lead stores the returned `output_path` and summary text for postflight use. The lead does NOT
read the unified report file — the synthesis summary is sufficient for postflight metadata.

### Synthesis Failure Handling

If the synthesis agent dispatch fails or times out:

1. Preserve all raw teammate finding files (they are already on disk)
2. Set artifact path to the most complete teammate finding (Teammate A preferred)
3. Mark status as `partial` in postflight
4. Log: "Synthesis failed: {reason}. Raw teammate findings preserved at {paths}"
5. Return to user with guidance to retry `/research {N}` (single-agent mode) for a synthesized report
