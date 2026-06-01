---
next_project_number: 620
---

# TODO

## Task Order

*Updated 2026-06-01. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,626 | -- | agent-system |

**Grouped by Topic** (indented = depends on parent):

### Agent System

626 [COMPLETED] — Update orchestrate.md command multi-task dispatch to invoke skill

### Uncategorized

78 [PLANNED] — fix himalaya smtp authentication failure
87 [RESEARCHED] — investigate wezterm terminal directory change

## Tasks

### 627. Fix Task Order regeneration after task creation
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Report**: [specs/627_fix_task_order_regeneration/reports/01_task-order-regen.md]
- **Plan**: [specs/627_fix_task_order_regeneration/plans/01_task-order-regen.md]
- **Summary**: [specs/627_fix_task_order_regeneration/summaries/01_task-order-regen-summary.md]

**Description**: Fix Task Order regeneration after task creation. (1) Fix `shift 3` bug in `generate-task-order.sh` line 53 that fails under `set -euo pipefail` when fewer than 3 follow-up args are provided. (2) Ensure task-creating commands (`/task`, `/meta`, `/fix-it`, `/spawn`, `/errors`) add new topics to `active_topics` array in state.json when assigning a topic not already present. (3) Verify the non-blocking `generate-task-order.sh` call in each task-creating command actually persists its output to TODO.md Task Order section.

---

### 626. Update orchestrate.md command for single-agent multi-task dispatch
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #625

**Description**: Update orchestrate.md command multi-task dispatch to invoke skill-orchestrate once with all task numbers instead of once per task per wave. Move wave construction (Kahn's algorithm) from command into skill args or pass pre-computed waves. Update multi-task-operations.md Section 13 to document single-agent orchestration pattern.

---

### 625. Refactor skill-orchestrate for single-agent multi-task orchestration
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Report**: [specs/625_orchestrate_single_agent_multi_task/reports/01_orchestrate-refactor.md]
- **Plan**: [specs/625_orchestrate_single_agent_multi_task/plans/01_orchestrate-refactor.md]
- **Summary**: [specs/625_orchestrate_single_agent_multi_task/summaries/01_orchestrate-refactor-summary.md]

**Description**: Refactor skill-orchestrate to support multi-task mode where a single orchestrator agent manages all tasks instead of spawning one agent per task. Add multi-task code path to SKILL.md state machine: single agent receives all task numbers and dependency graph, tracks per-task phase in a compact status table, dispatches phase-specific workers (research-agent, planner-agent, impl-agent) directly using wave-based dependency-aware scheduling. Reduces orchestration overhead from O(N * 44k) to O(1 * 44k) tokens. Also fix TODO.md synchronization: ensure the single orchestrator properly calls update-task-status.sh to sync status markers in TODO.md (not just state.json) and calls link-artifact-todo.sh after artifact creation to link reports/plans/summaries in TODO.md task entries.

---

### 624. Fix orchestrate postflight status sync and Task Order regeneration
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None

**Description**: Fix orchestrate command to properly update task status and regenerate Task Order after each agent dispatch. (1) Add postflight status update call in skill-orchestrate Stage 5 after handoff reading — map dispatch_status to operation and call skill_postflight_update() which triggers update-task-status.sh for state.json, TODO.md, and Task Order regeneration via Mode B. (2) Add orchestrate case to command-gate-out.sh case statement mapping to expected_status=completed as defensive backup. (3) Fix operator precedence issue on line 63-64 of command-gate-out.sh.

---

### 623. Add multi-task + dependency-aware dispatch to /orchestrate
- **Effort**: 2-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Report**: [specs/623_orchestrate_multi_task_dispatch/reports/01_multi-task-orchestrate.md]
- **Plan**: [specs/623_orchestrate_multi_task_dispatch/plans/01_multi-task-orchestrate-plan.md]
- **Summary**: [specs/623_orchestrate_multi_task_dispatch/summaries/01_multi-task-orchestrate-summary.md]

**Description**: Add multi-task argument support to /orchestrate command with dependency-aware execution ordering. (1) Update orchestrate.md STAGE 0 to use parse-command-args.sh for multi-task parsing with single-task fallthrough. (2) Add batch validation and dependency graph construction from state.json dependencies field. (3) Implement topological wave dispatch: tasks without inter-dependencies run in parallel via concurrent skill-orchestrate invocations; tasks with dependencies wait for predecessors to complete before launching. (4) Add consolidated output and batch commit for multi-task runs. (5) Update multi-task-operations.md with orchestrate-specific section covering dependency-aware dispatch vs pure-parallel. (6) Update CLAUDE.md command table to show new argument syntax (N[,N-N]).

---

### 622. Fix Task Order status sync and completed task pruning
- **Effort**: 2-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #620
- **Plan**: [622_fix_task_order_status_sync_pruning/plans/01_status-sync-plan.md]
- **Summary**: [622_fix_task_order_status_sync_pruning/summaries/01_status-sync-summary.md]

**Description**: Fix Task Order status sync and completed task pruning. Three sub-issues: (1) update-task-status.sh Phase 3 uses grep pattern that may fail on hand-curated Task Order formats - make the pattern more robust. (2) Verify Mode B terminal transition regeneration is correctly triggering in practice (task 232 shows as COMPLETED in BimodalLogic Task Order, suggesting regeneration did not fire). (3) Investigate whether link-artifact-todo.sh or agents are incorrectly appending artifact paths (- **Plans**: [...], - **Research**: [...]) into the Task Order section instead of only into the Tasks section entries. The symptoms in BimodalLogic show artifact links embedded in Task Order tree entries.

---

### 621. Add Task Order regeneration trigger to /revise postflight
- **Effort**: <1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #620

**Description**: Add Task Order regeneration trigger to /revise postflight. The skill-reviser SKILL.md postflight (after Stage 9 git commit) does not call generate-task-order.sh --update-todo. Add a non-blocking call matching the pattern in skill-todo Stage 10.5. Also update the regeneration triggers table in state-management.md and task-order-format.md to document /revise as a trigger event.

---

### 620. Fix generate-task-order.sh to handle Task Order sections
- **Effort**: 2-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Research**: [specs/620_fix_task_order_generation/reports/01_task-order-research.md]
- **Plan**: [specs/620_fix_task_order_generation/plans/01_fix-task-order.md]
- **Dependencies**: None

**Description**: Fix generate-task-order.sh to properly handle Task Order sections. Three sub-issues: (1) Completed tasks like #232 still appear in Task Order despite being terminal - verify the script properly excludes them. (2) The description field used in tree display may contain artifact paths instead of task descriptions - investigate why artifact-like content appears. (3) Ensure the script works correctly for projects with both auto-generated topic headings and hand-curated Track/Tier/Phase headings. The BimodalLogic project uses custom heading structure that diverges from the auto-generated format. Either (a) make the script preserve custom structure during regeneration, or (b) ensure projects configure state.json topics to produce equivalent auto-generated output. Also check that link-artifact-todo.sh is not incorrectly matching task numbers in the Task Order section.

---

### 619. Syncprotect-aware extension verification
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Dependencies**: None
- report: [Research on making extension verification syncprotect-aware]
- specs/619_syncprotect_aware_extension_verification/plans/01_syncprotect-aware-verification.md: [Implementation plan with 3 phases]

**Description**: Make the extension verification system syncprotect-aware and fix false-positive legacy core detection. Three tightly coupled changes:

1. **verify.lua**: Load `.syncprotect` in `verify_extension()` and pass protected paths to `verify_rules()` and `verify_context()`. Skip protected paths instead of reporting them as "Missing rule" or "Missing context". Optionally report them as "protected" (informational, not warning). The `load_syncprotect()` function already exists in `loader.lua` -- extract to a shared helper so both modules can use it.

2. **init.lua**: In `detect_legacy_core()`, read core's `manifest.provides.agents` list and only flag `.md` files that appear in that list. Currently ANY `.md` file in `.claude/agents/` triggers the legacy warning, causing false positives for custom project-specific agents like `port-agent.md`.

3. **Shared helper**: Extract the syncprotect parsing logic from `loader.lua:load_syncprotect()` (lines 16-44) into a shared utility module so both `loader.lua` and `verify.lua` can use it without code duplication or tight coupling.

**Observed symptoms** (in zed repo): `plan-format-enforcement.md` and `context/repo/project-overview.md` are listed in `.syncprotect` but flagged as "Missing rule" and "Missing context". `port-agent.md` triggers false "Legacy core detected" warning.

**Files**: `lua/neotex/plugins/ai/shared/extensions/verify.lua`, `lua/neotex/plugins/ai/shared/extensions/init.lua`, `lua/neotex/plugins/ai/shared/extensions/loader.lua`

---

### 618. Add reload option to extension picker
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Dependencies**: None
- **Report**: [specs/618_picker_reload_extensions/reports/01_picker-reload.md]
- **Plan**: [specs/618_picker_reload_extensions/plans/01_picker-reload-plan.md]
- **Summary**: [specs/618_picker_reload_extensions/summaries/01_picker-reload-summary.md]

**Description**: Add reload functionality to the `<leader>al` extension picker. Phase 1: When pressing `<CR>` on an already-loaded extension, show a `vim.ui.select` submenu with Unload/Reload/Cancel options instead of directly unloading. Reload calls the existing `manager.reload()` function at `extensions/init.lua:690-714`. Phase 2: Add a `[Reload All]` special entry just above `[Keyboard Shortcuts]` that wipes and reloads all currently loaded extensions and the core agent system. Files: `lua/neotex/plugins/ai/claude/commands/picker/init.lua` (CR handler at ~line 161, reload-all action), `lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua` (new special entry above keyboard shortcuts).

---

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

