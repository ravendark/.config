# Topic Assignment Pattern

**Created**: 2026-06-10
**Purpose**: Canonical reference for topic picker logic in commands/skills
**Audience**: Commands and skills that assign topics to tasks

## Overview

Topic picker logic was duplicated across ~6 files (~147 lines) in the agent system. The
`active_topics` maintenance jq snippet appeared verbatim 5 times; the full interactive
AskUserQuestion picker was inlined 3 times.

This document and `manage-topics.sh` replace all inline implementations. Commands should
call `manage-topics.sh` for state.json operations and copy the AskUserQuestion templates
from this document for user interaction.

### Three Assignment Modes

| Mode | Used by | Picker shown? | State updated by |
|------|---------|---------------|-----------------|
| **A: Interactive** | `/task` create, `/task` sync backfill, `/meta` interview Stage 4.5 | Yes (full picker) | `manage-topics.sh add` + `manage-topics.sh set` |
| **B: Inherit** | `/task --expand`, `/task --recover` follow-up tasks, `/spawn` | No | `manage-topics.sh add` + `manage-topics.sh set` |
| **C: Suggest** | `/review`, `/fix-it` | No | `manage-topics.sh add` + `manage-topics.sh set` |

---

## Mode A: Interactive

Show a picker when the user is actively creating or reviewing a task and can make a
deliberate topic choice.

**Caller locations**:
- `/task` — Create new task (task creation interview, last step)
- `/task --sync` — Backfill missing topics for existing tasks
- `/meta` — Interview Stage 4.5 (group tasks by topic before creation)

### Step 1: Build options array

```bash
# Get existing active topics from state.json
mapfile -t existing_topics < <(bash .claude/scripts/manage-topics.sh list)

# Build AskUserQuestion options: existing + "New topic..." + "Skip"
options=()
for t in "${existing_topics[@]}"; do
  options+=("$t")
done
options+=("New topic...")
options+=("Skip (no topic)")
```

### Step 2: Show picker

```json
{
  "question": "Assign a topic to this task?",
  "type": "select",
  "options": ["<existing-topic-1>", "<existing-topic-2>", "New topic...", "Skip (no topic)"]
}
```

### Step 3: Handle "New topic..." branch

If the user selects "New topic...", show a follow-up free-text question:

```json
{
  "question": "Enter new topic name (lowercase, kebab-case, e.g. 'agent-system'):",
  "type": "freeText"
}
```

Validate: non-empty, no spaces (suggest replacing spaces with hyphens if entered).

### Step 4: Update state

```bash
# topic is either the selected existing value or the new free-text value
if [[ "$topic" == "Skip (no topic)" || -z "$topic" ]]; then
  : # no-op, do not assign
else
  bash .claude/scripts/manage-topics.sh add "$topic"
  bash .claude/scripts/manage-topics.sh set "$task_num" "$topic"
fi
```

---

## Mode B: Inherit

Propagate the parent task's topic to child tasks automatically, without showing a picker.
Used for tasks that are derived from or blocked by another task and should share its
organizational context.

**Caller locations**:
- `/task --expand N` — Sub-tasks inherit the expanded task's topic
- `/task --recover N` — Recovery tasks inherit the original task's topic
- `/spawn N` — Spawned unblock tasks inherit the blocked task's topic

### Canonical bash

```bash
# Read parent topic from state.json
parent_topic=$(jq -r --arg num "$parent_task_num" \
  '.active_projects[] | select(.project_number == ($num | tonumber)) | .topic // empty' \
  specs/state.json)

# Only assign if parent had a topic
if [[ -n "$parent_topic" ]]; then
  bash .claude/scripts/manage-topics.sh add "$parent_topic"
  bash .claude/scripts/manage-topics.sh set "$new_task_num" "$parent_topic"
fi
# If parent has no topic, no topic is assigned (no fallback picker in current implementation)
```

---

## Mode C: Suggest

Infer the topic from the path of files being reviewed or the type of fix, without showing
a picker. Used for batch task creation where user interaction would be disruptive.

**Caller locations**:
- `/review` — Code review creates tasks; topic inferred from reviewed path
- `/fix-it` — Tag scanner creates tasks; topic inferred from file path

### Path heuristic table

| File path prefix | Inferred topic |
|-----------------|----------------|
| `.claude/` or `specs/` | `agent-system` |
| `lua/` or `after/` | `neovim` |
| `home/` or `modules/` (nix) | `nix-config` |
| other | *(no topic assigned)* |

### Canonical bash

```bash
# file_path is the path of the file being reviewed/fixed
infer_topic_from_path() {
  local path="$1"
  if [[ "$path" == .claude/* || "$path" == specs/* ]]; then
    echo "agent-system"
  elif [[ "$path" == lua/* || "$path" == after/* ]]; then
    echo "neovim"
  elif [[ "$path" == home/* || "$path" == modules/* ]]; then
    echo "nix-config"
  else
    echo ""
  fi
}

inferred=$(infer_topic_from_path "$file_path")
if [[ -n "$inferred" ]]; then
  bash .claude/scripts/manage-topics.sh add "$inferred"
  bash .claude/scripts/manage-topics.sh set "$task_num" "$inferred"
fi
```

---

## State Update Reference

All state mutations go through `manage-topics.sh`. Never write jq topic snippets inline.

| Subcommand | Description | Example |
|-----------|-------------|---------|
| `list` | Print all active topics, one per line | `bash .claude/scripts/manage-topics.sh list` |
| `add TOPIC` | Add topic to active_topics (idempotent) | `bash .claude/scripts/manage-topics.sh add "agent-system"` |
| `set TASK TOPIC` | Assign topic to task + add to active_topics | `bash .claude/scripts/manage-topics.sh set 42 "agent-system"` |
| `validate TOPIC` | Exit 0 if present, exit 1 if not | `bash .claude/scripts/manage-topics.sh validate "agent-system"` |

**Exit codes**: `0`=success/found, `1`=not-found/bad-args, `2`=state.json-error,
`3`=jq-write-failure, `4`=task-not-found.

---

## Related Documentation

- `.claude/scripts/manage-topics.sh` — Script implementation with full inline docs
- `.claude/rules/state-management.md` — State update patterns and schema
- `.claude/context/patterns/jq-escaping-workarounds.md` — jq safety (Issue #1132)
- `.claude/context/reference/state-management-schema.md` — Full state.json schema
