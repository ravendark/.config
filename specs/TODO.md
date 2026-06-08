---
next_project_number: 640
---

# TODO

## Task Order

*Updated 2026-06-08. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,639 | -- | agent-system |

**Grouped by Topic** (indented = depends on parent):

### Agent System

639 [NOT STARTED] — fix orchestrate todo sync

### Uncategorized

78 [PLANNED] — fix himalaya smtp authentication failure
87 [RESEARCHED] — investigate wezterm terminal directory change

## Tasks

### 639. Fix /orchestrate TODO.md status sync and artifact linking
- **Effort**: 1 hour
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: None

**Description**: Replace bash function references in `skill-orchestrate/SKILL.md` with explicit, standalone bash commands that the orchestrator agent can execute directly via the Bash tool. The orchestrator currently updates state.json correctly but never updates TODO.md status markers or links artifacts because it treats `skill_preflight_update`, `skill_postflight_update`, and `skill_link_artifact_from_handoff` as pseudocode rather than callable functions (they require `source skill-base.sh` which agents don't run). Changes needed in both single-task (Stages 4-5) and multi-task (Stages MT-3/MT-4) sections: (1) Replace `skill_preflight_update` with `bash .claude/scripts/update-task-status.sh preflight "$task_number" "$phase" "$session_id"`, (2) Replace `skill_postflight_update` with `bash .claude/scripts/update-task-status.sh postflight "$task_number" "$phase" "$session_id"`, (3) Replace `skill_link_artifact_from_handoff` and `skill_link_artifacts` with explicit artifact-type-to-anchor mapping plus `bash .claude/scripts/link-artifact-todo.sh` calls that parse the handoff JSON for artifact path and type.

---

### 638. Fix generate-task-order.sh to create Task Order section when missing
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None

**Description**: Fix `generate-task-order.sh` to handle the case where `## Task Order` doesn't exist in TODO.md. In `--update-todo` mode, if the `## Task Order` section is not found, INSERT it before the first `## Tasks` section instead of failing with a warning. This makes the script idempotent -- it creates the section on first run and replaces it on subsequent runs. Also verify the script generates clean output matching the BimodalLogic format (waves table + topic tree, no artifact links in task order entries). The issue was discovered when cslib's TODO.md was created without a Task Order section, and `generate-task-order.sh` could only replace (not create) that section.

---

### 87. Investigate terminal directory change when opening neovim in wezterm
- **Effort**: TBD
- **Status**: [PLANNED]
- **Research Started**: 2026-02-13
- **Research Completed**: 2026-02-13
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [087_investigate_wezterm_terminal_directory_change/reports/research-001.md]

**Description**: Investigate why the terminal working directory changes to a project root when opening neovim sessions in wezterm from the home directory (~). Determine whether this behavior is caused by neovim or wezterm (configured in ~/.dotfiles/config/). Identify if any functionality depends on this behavior before modifying it. Goal is to avoid changing the terminal directory unless necessary.

---

### 78. Fix Himalaya SMTP authentication failure when sending emails
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [078_fix_himalaya_smtp_authentication_failure/reports/research-001.md]
- **Plan**: [078_fix_himalaya_smtp_authentication_failure/plans/implementation-001.md]

**Description**: Fix Gmail SMTP authentication failure when sending emails via Himalaya (<leader>me). Error: "Authentication failed: Code: 535, Enhanced code: 5.7.8, Message: Username and Password not accepted". The error occurs with TLS connection attempts and persists through multiple retry attempts. Identify and fix the root cause of the SMTP credential configuration.

