---
next_project_number: 608
---

# TODO

## Task Order

*Updated 2026-05-22. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87 | -- | -- |

**Grouped by Topic** (indented = depends on parent):

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change

## Tasks

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

## Recommended Order

| Priority | Task | Status | Next Action |
|----------|------|--------|-------------|
| 1 | 87 | [RESEARCHED] | /plan 87 |
| 2 | 78 | [PLANNED] | /implement 78 |

---

## Recently Completed

| Task | Name | Completed |
|------|------|-----------|
| 607 | Improve research agents multi-angle team strategy | 2026-05-22 |
| 606 | Fix extension doc-lint failures | 2026-05-22 |
| 602 | Update wezterm dim/bright colors | 2026-05-22 |
| 600 | Revise docs architecture post-refactor | 2026-05-22 |
| 599 | Update CLAUDE.md extension documentation | 2026-05-22 |
| 598 | Progressive disclosure context system | 2026-05-22 |
| 597 | Refactor task/revise/todo/review commands | 2026-05-22 |
| 596 | Create /orchestrate command and skill | 2026-05-22 |
| 595 | Refactor research/plan/implement commands | 2026-05-22 |
| 605 | Reverse Task Order tree direction | 2026-05-22 |
| 604 | Add Task Order regeneration to task-creating commands | 2026-05-22 |
| 603 | Fix /meta pre-confirmation pattern | 2026-05-22 |
| 601 | Simplify notification pipeline and merge vocabulary | 2026-05-22 |

