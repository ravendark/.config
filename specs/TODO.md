---
next_project_number: 617
---

# TODO

## Task Order

*Updated 2026-05-25. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,616 | -- | -- |

**Grouped by Topic** (indented = depends on parent):

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change
616 [NOT STARTED] — The archive-task.sh script moves task directories to archive/ and

## Tasks

### 616. Fix archive-task.sh to remove archived entries from TODO.md
- **Effort**: 30 minutes
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: None

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

