---
next_project_number: 633
---

# TODO

## Task Order

*Updated 2026-06-02. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87 | -- | -- |

**Grouped by Topic** (indented = depends on parent):

### Uncategorized

78 [PLANNED] — fix himalaya smtp authentication failure
87 [RESEARCHED] — investigate wezterm terminal directory change

## Tasks


### 632. Fix generate-task-order.sh to bootstrap Task Order section if missing
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Topic**: workflow-refactor
- **Research**: [632_fix_task_order_bootstrap/reports/01_task-order-bootstrap-research.md]
- **Plan**: [632_fix_task_order_bootstrap/plans/01_bootstrap-implementation-plan.md]
- **Summary**: [632_fix_task_order_bootstrap/summaries/01_bootstrap-implementation-summary.md]

**Description**: `generate-task-order.sh` operates in replace-only mode — it searches for an existing `## Task Order` heading in TODO.md and replaces its content. If the section was never created (as in new child projects like BimodalHarness), the script warns and exits without creating it. Fix the script to detect a missing `## Task Order` section and append/insert it automatically before running the replace logic. This makes the script idempotent and fixes Task Order generation for all child projects after sync.

**Key files**: `.claude/scripts/generate-task-order.sh` (add create-if-missing logic around the `replace_section()` function)

---

### 628. Add preflight status updates to skill-orchestrate
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Topic**: workflow-refactor
- **Research**: [628_add_preflight_to_orchestrate/reports/01_preflight-orchestrate-research.md]
- **Plan**: [628_add_preflight_to_orchestrate/plans/01_preflight-implementation-plan.md]
- **Summary**: [628_add_preflight_to_orchestrate/summaries/01_preflight-implementation-summary.md]

**Description**: Add `skill_preflight_update()` calls before each agent dispatch in both single-task (Stage 4) and multi-task (Stage MT-4) modes of `skill-orchestrate`. Before dispatching a research agent, set status to `[RESEARCHING]`. Before dispatching planner-agent, set status to `[PLANNING]`. Before dispatching an implement agent, set status to `[IMPLEMENTING]`. This ensures the 4-location atomic update fires for every lifecycle transition, matching the behavior of standalone `/research`, `/plan`, and `/implement` commands.

**Key files**: `.claude/skills/skill-orchestrate/SKILL.md` (Stage 4 single-task dispatch, Stage MT-4 multi-task dispatch), `.claude/scripts/skill-base.sh` (`skill_preflight_update` function), `.claude/scripts/update-task-status.sh`

---

### 629. Add "revise" support to update-task-status.sh and skill-reviser
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Topic**: workflow-refactor
- **Research**: [629_add_revise_status_support/reports/01_revise-status-research.md]
- **Plan**: [629_add_revise_status_support/plans/01_revise-status-implementation.md]
- **Summary**: [629_add_revise_status_support/summaries/01_revise-implementation-summary.md]

**Description**: Extend `update-task-status.sh` to accept `target_status="revise"` with preflight mapping to `[REVISING]` and postflight mapping to `[PLANNED]`. Update `skill-reviser/SKILL.md` to call `skill_preflight_update` in its Stage 2 (currently explicitly skipped). This brings `/revise` into alignment with `/research`, `/plan`, and `/implement` for consistent status tracking.

**Key files**: `.claude/scripts/update-task-status.sh` (line 69 - add "revise" case), `.claude/skills/skill-reviser/SKILL.md` (Stage 2 - add preflight call), `.claude/context/standards/status-markers.md` (already defines REVISING/REVISED)

---

### 630. Consolidate orchestrate postflight with skill-base.sh pattern
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: 628
- **Topic**: workflow-refactor
- **Research**: [630_consolidate_orchestrate_postflight/reports/01_consolidate-postflight.md]
- **Plan**: [630_consolidate_orchestrate_postflight/plans/01_consolidate-postflight.md]
- **Summary**: [630_consolidate_orchestrate_postflight/summaries/01_consolidate-postflight-summary.md]

**Description**: The orchestrate skill has its own inline postflight logic (Stage 5 lines 368-413, Stage MT-4 lines 971-1058) that duplicates the pattern in `skill-base.sh`. Refactor to use the same `skill_link_artifacts()` and `skill_postflight_update()` functions consistently. Keep orchestrate-specific handling (handoff reading, drift detection) as orchestrate-specific code, but route the core status update through `skill-base.sh` to eliminate drift between the two parallel postflight paths.

**Key files**: `.claude/skills/skill-orchestrate/SKILL.md` (Stage 5, Stage MT-4 postflight), `.claude/scripts/skill-base.sh` (`skill_postflight_update`, `skill_link_artifacts`)

---

### 631. Clean up stale status documentation and consolidate
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: 628, 629, 630
- **Topic**: workflow-refactor
- **Research**: [631_cleanup_stale_status_docs/reports/01_stale-status-docs.md]
- **Plan**: [631_cleanup_stale_status_docs/plans/01_stale-status-docs.md]
- **Summary**: [631_cleanup_stale_status_docs/summaries/01_stale-status-docs-summary.md]

**Description**: (a) Remove or redirect the deprecated `status-transitions.md` file. (b) Update `status-markers.md` to replace all "status-sync-manager" references with the current infrastructure (`update-task-status.sh` via `skill-base.sh`). (c) Evaluate whether `inline-status-update.md` should be removed or marked deprecated. (d) Update `skill-status-sync/SKILL.md` "standalone use only" note to document orchestrate's interaction. (e) Ensure `state-management.md` correctly documents the orchestrate flow. (f) Update any CLAUDE.md sections that reference outdated status sync patterns.

**Key files**: `.claude/context/workflows/status-transitions.md`, `.claude/context/standards/status-markers.md`, `.claude/context/patterns/inline-status-update.md`, `.claude/skills/skill-status-sync/SKILL.md`, `.claude/rules/state-management.md`

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

