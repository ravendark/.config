---
next_project_number: 618
---

# TODO

## Task Order

*Updated 2026-05-25. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87 | -- | -- |

**Grouped by Topic** (indented = depends on parent):

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change

## Tasks

### 617. Lean LSP-first verification policy for implementation agents
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Report**: [specs/617_lean_lsp_first_verification/reports/01_lsp-first-verification.md]
- **Plan**: [specs/617_lean_lsp_first_verification/plans/01_lsp-first-plan.md]
- **Summary**: [specs/617_lean_lsp_first_verification/summaries/01_lsp-first-summary.md]

**Description**: Update lean extension rules, agent, and implementation flow to prefer lean-lsp MCP tools over `lake build` for per-step verification. Currently agents run `lake build` after every edit (3x per phase on large files). Changes: (1) Add `lean_verify` to essential MCP tools (currently undocumented), (2) Replace per-step `lake build` with `lean_goal` checks, (3) Position `lean_multi_attempt` as preferred pre-edit tactic trial before committing edits, (4) Prefer `lake build Module.Name` over bare `lake build` when full builds are needed, (5) Reserve full `lake build` for phase-end and final verification only. Files to modify: `.claude/extensions/lean/rules/lean4.md`, `.claude/extensions/lean/agents/lean-implementation-agent.md`, `.claude/extensions/lean/context/project/lean4/agents/lean-implementation-flow.md`.

---

### 616. Fix archive-task.sh to remove archived entries from TODO.md
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- specs/616_fix_archive_task_todo_cleanup/reports/01_archive-todo-cleanup.md: [Research]
- specs/616_fix_archive_task_todo_cleanup/plans/01_archive-todo-plan.md: [Plan]
- specs/616_fix_archive_task_todo_cleanup/summaries/01_archive-todo-summary.md: [Summary]

**Description**: The `archive-task.sh` script moves task directories to `archive/` and updates `state.json` (removing from `active_projects`, adding to `completed_projects`) but does NOT remove the corresponding task entry block from `TODO.md`. This leaves stale `[COMPLETED]` entries in `TODO.md` after `/todo` runs. Fix: add a step to `archive-task.sh` that removes the full task entry block (from `### {N}.` to the next `---` or `###` delimiter) from `TODO.md` after archiving. Also update the extension copy at `.claude/extensions/core/scripts/archive-task.sh`.

---

### 87. Investigate terminal directory change when opening neovim in wezterm
- **Effort**: TBD
- **Status**: [RESEARCHED]
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

