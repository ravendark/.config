---
next_project_number: 647
---

# TODO

## Task Order

*Updated 2026-06-09. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87 | -- | -- |

**Grouped by Topic** (indented = depends on parent):

### Uncategorized

78 [PLANNED] — fix himalaya smtp authentication failure
87 [RESEARCHED] — investigate wezterm terminal directory change

## Tasks

### 642. Fix orchestrator_mode=false for research/plan dispatch
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Fix orchestrator_mode=false for research/plan dispatch in skill-orchestrate/SKILL.md lines 934 and 959: change to orchestrator_mode true so handoff JSON is written and orchestrator postflight chain works for all phases not just implement.

---

### 643. Eliminate dual postflight ownership
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 642 (Fix orchestrator_mode)

**Description**: Eliminate dual postflight ownership: when orchestrator_mode=true the skill should SKIP its own skill_postflight_update and only write the handoff JSON so the orchestrator exclusively owns status transitions in state.json and TODO.md.

---

### 644. Add reconciliation preflight to orchestrator
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 643 (Eliminate dual postflight)
- **Research**: [644_reconciliation_preflight/reports/01_reconciliation-preflight.md]
- **Plan**: [644_reconciliation_preflight/plans/01_reconciliation-preflight.md]
- **Summary**: [644_reconciliation_preflight/summaries/01_reconciliation-preflight-summary.md]

**Description**: Add reconciliation preflight to orchestrator: at the start of each /orchestrate invocation scan task directories for artifacts that exist but whose status has not been promoted, replay missed postflight to provide self-healing for crashed agents missed handoffs and interrupted sessions.

---

### 645. Fix parallel write safety for state.json
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 643 (Eliminate dual postflight)
- **Research**: [645_parallel_write_safety/reports/01_parallel-write-safety.md]
- **Plan**: [645_parallel_write_safety/plans/01_parallel-write-safety.md]
- **Summary**: [645_parallel_write_safety/summaries/01_parallel-write-safety-summary.md]

**Description**: Fix parallel write safety for state.json: replace shared specs/tmp/state.json temp path with mktemp unique per write, add flock mutex around state.json write operations in update-task-status.sh to prevent last-write-wins corruption when multiple agents write concurrently.

---

### 646. Harden TODO.md status updates
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Replace brittle sed pattern matching in update-task-status.sh phase 2 with robust awk/line-number approach that does not fail silently when status text format varies.

---

### 641. Fix meta-builder-agent topic assignment
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [641_meta_builder_topic_picker/reports/01_topic-picker-research.md]
- **Plan**: [641_meta_builder_topic_picker/plans/01_topic-picker-plan.md]
- **Summary**: [641_meta_builder_topic_picker/summaries/01_topic-picker-summary.md]

**Description**: Replace the nonexistent "keyword heuristic (same as `/task` topic inference)" in `meta-builder-agent.md` with an actual interactive topic picker. The meta-builder currently references auto-inference that doesn't exist, so batch-created tasks via `/meta` silently skip topic assignment — all tasks end up under "Uncategorized" in Task Order.

**Changes needed**:
1. **Stage 5 (ReviewAndConfirm)**: Add a topic assignment step before the confirmation table. Present AskUserQuestion with options from `active_topics` + "New topic..." + "Skip". Allow batch assignment (all tasks get same topic) or per-task assignment.
2. **Stage 5 confirmation table**: Ensure the Topic column displays assigned values so the user can verify before confirming.
3. **Stage 6 (CreateTasks)**: Replace the "keyword heuristic" reference with writing the user-selected topic to each state.json entry's `topic` field.
4. **Stage 3.5 UX clarity**: Consider renaming the "Topic Consolidation" header to "Task Consolidation" to avoid confusion with topic assignment — Stage 3.5 merges tasks, it doesn't assign topics.

---

### 640. Add topic revision stage to /todo skill
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [640_todo_topic_revision/reports/01_topic-revision-research.md]
- **Plan**: [640_todo_topic_revision/plans/01_topic-revision-plan.md]
- **Summary**: [640_todo_topic_revision/summaries/01_topic-revision-summary.md]

**Description**: Add topic awareness to `skill-todo/SKILL.md` so that running `/todo` offers to assign or revise topic groupings. Currently the skill has zero topic handling — tasks without topics stay uncategorized forever unless the user manually edits state.json.

**Changes needed**:
1. **New stage in skill-todo** (between task scanning and archiving): Detect active tasks missing a `topic` field. If any found, present AskUserQuestion with existing `active_topics` + "New topic..." + "Skip all". Allow the user to assign topics to uncategorized tasks.
2. **Orphan topic cleanup**: After archiving tasks, check if any `active_topics` values are no longer referenced by any active task. If so, present AskUserQuestion offering to remove orphaned topics from the `active_topics` array.
3. **`/task --sync` Step 6.5**: Add "New topic..." option to the existing backfill picker (currently only shows existing `active_topics`, no way to create a new topic during sync).

---

### 639. Fix /orchestrate TODO.md status sync and artifact linking
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [639_fix_orchestrate_todo_sync/reports/01_todo-sync-analysis.md]
- **Plan**: [639_fix_orchestrate_todo_sync/plans/01_fix-todo-sync-plan.md]
- **Summary**: [639_fix_orchestrate_todo_sync/summaries/01_fix-summary.md]

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
