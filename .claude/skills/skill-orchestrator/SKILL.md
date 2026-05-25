---
name: skill-orchestrator
description: Route commands to appropriate workflows based on task type and status. Invoke when executing /task, /research, /plan, /implement commands.
allowed-tools: Read, Glob, Grep, Agent
# Context loaded on-demand via @-references (see Context Loading section)
---

# Orchestrator Skill

Central routing intelligence for the task management system.

## Context Loading

Load context on-demand when needed:
- `@.claude/context/orchestration/orchestration-core.md` - Routing, delegation, session tracking
- `@.claude/context/orchestration/state-management.md` - Task lookup and status validation
- `@.claude/context/index.json` - Full context discovery index

## Trigger Conditions

This skill activates when:
- A slash command needs task-type-based routing
- Task context needs to be gathered before delegation
- Multi-step workflows require coordination

## Core Responsibilities

### 1. Task Lookup

Given a task number, retrieve full context using targeted extraction:
```bash
# Extract only the needed task fields (do NOT read the full state.json file)
task_data=$(jq -r --argjson num "$N" \
  '.active_projects[] | select(.project_number == $num)' \
  specs/state.json)
task_type=$(echo "$task_data" | jq -r '.task_type // "general"')
status=$(echo "$task_data" | jq -r '.status')
project_name=$(echo "$task_data" | jq -r '.project_name')
description=$(echo "$task_data" | jq -r '.description // ""')

# If description is missing from state.json, grep TODO.md for the task section (do NOT read the full file)
if [ -z "$description" ]; then
  description=$(grep -A5 "^\- \[" specs/TODO.md | grep -i "${project_name}" | head -1)
fi
```

### 2. Task-Type-Based Routing

Route to appropriate skill based on task type:

**Core Types** (always available):

| Task Type | Research Skill | Implementation Skill |
|-----------|---------------|---------------------|
| general | skill-researcher | skill-implementer |
| meta | skill-researcher | skill-implementer |
| markdown | skill-researcher | skill-implementer |

**Extension Types** (loaded from extension manifests):

| Task Type | Research Skill | Implementation Skill |
|-----------|---------------|---------------------|
| lean4, lean | skill-lean-research | skill-lean-implementation |
| neovim | skill-neovim-research | skill-neovim-implementation |
| nix | skill-nix-research | skill-nix-implementation |

**Dynamic resolution**: For task types not listed above, check `.claude/extensions/{task_type}/manifest.json` and read its `routing.research` and `routing.implement` entries for the task_type key.

### 3. Status Validation

Before routing, validate task status is not terminal:

```
if status in [completed, abandoned, expanded]:
  ABORT "Task is in terminal state [$status]"
```

All operations (research, plan, implement, revise) are allowed from any non-terminal status.

### 4. Context Preparation

Prepare context package for delegated skill:
```json
{
  "task_number": 259,
  "task_name": "task_slug",
  "task_type": "general",
  "status": "planned",
  "description": "Full task description",
  "artifacts": {
    "research": ["path/to/research.md"],
    "plan": "path/to/plan.md"
  },
  "focus_prompt": "Optional user-provided focus"
}
```

## Execution Flow

```
1. Receive command context (task number, operation type)
2. Lookup task in state.json
3. Validate status for operation
4. Determine target skill by task_type
5. Prepare context package
6. Invoke target skill via Agent tool
7. Receive and validate result
8. Return result to caller
```

## Return Format

```json
{
  "status": "completed|partial|failed",
  "routed_to": "skill-name",
  "task_number": 259,
  "result": {
    "artifacts": [],
    "summary": "..."
  }
}
```

## Error Handling

- Task not found: Return clear error with suggestions
- Invalid status: Return error with current status and allowed operations
- Skill invocation failure: Return partial result with error details

---

## MUST NOT (Context Protection)

Task lookup MUST use targeted jq extraction, NOT full file reads. Specifically:

1. **MUST NOT read the full specs/state.json** -- use `jq -r --argjson num "$N" '.active_projects[] | select(.project_number == $num)' specs/state.json`
2. **MUST NOT read the full specs/TODO.md** -- use `grep -A5` for targeted task section lookup only if state.json lacks description

**Context budget target**: Task lookup should add no more than ~200 tokens above baseline.

Reference: @.claude/context/patterns/context-protective-lead.md

---

## MUST NOT (Postflight Boundary)

After routing to a skill, this skill MUST NOT:

1. **Edit source files** - All work is done by routed skills/agents
2. **Run build/test commands** - Verification is done by routed skills/agents
3. **Update task status** - Status updates are done by routed skills
4. **Create artifacts** - Artifact creation is done by routed skills/agents

The orchestrator is a **routing-only** skill. It:
- Looks up task context via targeted jq extraction
- Routes to appropriate skill based on task_type
- Passes through the routed skill's return

Reference: @.claude/context/standards/postflight-tool-restrictions.md
