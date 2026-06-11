---
next_project_number: 657
---

# TODO

## Task Order

*Updated 2026-06-11. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,652 | -- | wezterm-notifications, agent-system |

**Grouped by Topic** (indented = depends on parent):

### Wezterm Notifications

78 [PLANNED] — Fix Gmail SMTP authentication failure when sending emails via Him
87 [RESEARCHED] — Investigate why the terminal working directory changes to a proje

### Agent System

652 [NOT STARTED] — After ~1 week of the new pipeline running, review logs to verify 

## Tasks

### 656. Add topic assignment to commands with missing or partial coverage
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 654

**Description**: Add topic assignment to 6 task creation points that currently have missing or incomplete topic handling, using the shared topic-assignment-pattern.md and manage-topics.sh:

1. **skill-fix-it/SKILL.md** (PARTIAL): Keep existing auto-inference heuristic as a suggestion, but add user confirmation via the shared pattern suggest mode. User can accept, override, or skip.
2. **commands/review.md** (PARTIAL): Same as fix-it — auto-inference as suggestion + confirmation picker. Also add active_topics array update when new topics are created.
3. **skills/skill-project-overview/SKILL.md** (MISSING): Add topic picker call using shared pattern interactive mode.
4. **skills/skill-spawn/SKILL.md** (inherit, no fallback): Keep parent inheritance as primary, add fallback to shared pattern interactive mode when parent has no topic.
5. **commands/task.md --expand** (inherit, no fallback): Same as spawn — inherit parent topic, fallback picker when parent is topicless.
6. **commands/task.md --review** (inherit, no fallback): Same as spawn — inherit parent topic, fallback picker when parent is topicless.

Also update extension copies (.claude/extensions/core/) to match all changes.

---

### 655. Refactor existing topic pickers to use shared utilities
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 654

**Description**: Replace duplicated inline topic picker logic in 4 existing commands/agents with references to the shared topic-assignment-pattern.md and calls to manage-topics.sh:

1. **commands/task.md** (Step 4.5): Replace ~50 lines of inline picker instructions with reference to shared pattern (interactive mode)
2. **agents/meta-builder-agent.md** (Stage 4.5 AssignTopic): Replace ~60 lines of batch picker instructions with reference to shared pattern (interactive mode, batch variant)
3. **commands/task.md** (--sync Step 6.5): Replace backfill picker with reference to shared pattern (interactive mode per-task)
4. **skills/skill-todo/SKILL.md** (Stage 2.5 TopicRevision): Replace revision picker with reference to shared pattern (interactive mode)

Each location becomes: "Follow the topic assignment pattern from @.claude/context/patterns/topic-assignment-pattern.md" plus manage-topics.sh calls for state updates. Also update extension copies (.claude/extensions/core/) to match.

Net reduction: ~200 lines of duplicated picker instructions replaced by pattern references.

---

### 654. Create shared topic management utilities (manage-topics.sh + pattern doc)
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Plan**: [654_create_topic_management_utilities/plans/01_topic-management-plan.md]

**Description**: Create two shared topic management artifacts to replace ~200 lines of duplicated topic picker logic across commands:

1. **manage-topics.sh** script with subcommands:
   - `list`: Output active_topics from state.json as newline-delimited list
   - `add TOPIC`: Add a new topic to the active_topics array (idempotent)
   - `set TASK_NUM TOPIC`: Set the topic field on a task entry in state.json
   - `validate TOPIC`: Check if topic exists in active_topics (exit 0/1)
   Uses flock for write safety consistent with existing state.json write patterns.

2. **topic-assignment-pattern.md** shared context pattern document describing:
   - The canonical AskUserQuestion flow (read active_topics, build picker options, handle New topic/Skip responses)
   - Three assignment modes: interactive (full picker), inherit (parent topic with fallback picker), suggest (auto-inferred topic pre-selected, user can override)
   - State update instructions (call manage-topics.sh for mechanical operations)
   - Commands reference this pattern instead of inlining 50 lines of picker instructions each.

This task creates the foundation; tasks 655 and 656 consume these utilities.

---

### 653. Update all task creation commands to state.json-first pattern
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 649
- **Research**: [653_update_task_creation_commands_state_first/reports/01_pipeline-audit.md]
- **Plan**: [653_update_task_creation_commands_state_first/plans/01_task-creation-state-first.md]
- **Summary**: [653_update_task_creation_commands_state_first/summaries/01_task-creation-migration-summary.md]

**Description**: Update all task creation commands and agents to follow the state.json-first pattern: write to state.json, then call generate-todo.sh for regeneration. Currently 8 HIGH-priority writers create entries directly in TODO.md, which generate-todo.sh will silently overwrite. Files to update: (1) commands/task.md — Create, Recover, Followup, Expand, Sync, Abandon modes: replace all TODO.md Edit/sed operations with state.json updates + generate-todo.sh call. (2) commands/review.md — task creation and goal line: add active_goal field to state.json schema, replace TODO.md Edit with state.json update + generate-todo.sh. (3) skill-spawn/SKILL.md — child task creation, parent status/deps updates: replace 3 Edit operations with state.json writes + generate-todo.sh. (4) skill-fix-it/SKILL.md — fix-it task creation: replace TODO.md prepend with state.json write + generate-todo.sh. (5) skill-project-overview/SKILL.md — task creation + link-artifact-todo call: replace with state.json write + generate-todo.sh. (6) agents/meta-builder-agent.md — batch task creation: replace batch Edit insertion with state.json writes + generate-todo.sh. Also update archive-task.sh (Python entry removal) and vault-operation.sh (sed renumber/comment) to use generate-todo.sh instead of direct TODO.md manipulation.

---

### 652. Post-validation cleanup: remove obsolete scripts after logging review
- **Effort**: 1 hour
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 649, Task 651, Task 653

**Description**: After ~1 week of the new pipeline running, review logs to verify the new generate-todo.sh pipeline is working reliably. Check that: (1) no deprecation-logged old code paths are being hit, (2) TODO.md regeneration succeeds consistently, (3) no state.json/TODO.md sync drift. Then remove: link-artifact-todo.sh (fully replaced by state.json + regeneration), old TODO.md awk/sed manipulation code from update-task-status.sh, dead functions from skill-base.sh, any transitional compatibility shims. Clean up deprecation logging. Mark as deferred until validation period passes.

---

### 651. Update rules and documentation for new state.json-first architecture
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 649, Task 653
- **Research**: [651_update_rules_and_documentation/reports/01_docs-update-research.md]
- **Plan**: [651_update_rules_and_documentation/plans/01_docs-rules-update.md]
- **Summary**: [651_update_rules_and_documentation/summaries/01_docs-rules-update-summary.md]

**Description**: Update rules and documentation for new state.json-first architecture. Remove Two-Phase Update Pattern from state-management.md (no longer needed). Update CLAUDE.md agent system section. Update skill-status-sync to reference new pipeline (remove all Edit-TODO.md instructions from K1-K3). Remove redundant TODO.md Edit instructions from extension skills: skill-nix-implementation (K4-K5), skill-neovim-implementation (K6-K7), skill-nix-research (K8), skill-neovim-research (K9). Remove TODO.md description Edit from skill-reviser (K10). Update skill-todo to use generate-todo.sh instead of Edit-based entry removal (K17-K18) and sed-based vault renumber/comment (K19-K20). Update archive-task.sh to call generate-todo.sh instead of Python entry removal. Update commands/implement.md to remove defensive TODO.md status correction (C10-C11). Update artifact-formats.md if linking format changed. Update workflow-diagrams if they reference old dual-write flow. Ensure all documentation consistently describes the new flow: command -> state.json update -> generate-todo.sh -> TODO.md regenerated.

---

### 650. Create update-phase-status.sh for phase-level plan tracking
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [650_create_update_phase_status_script/reports/01_phase-status-research.md]
- **Plan**: [650_create_update_phase_status_script/plans/01_phase-status-script.md]
- **Summary**: [650_create_update_phase_status_script/summaries/01_phase-status-summary.md]

**Description**: Create update-phase-status.sh script for phase-level status tracking in plan files. Updates individual phase markers ([NOT STARTED] -> [IN PROGRESS] -> [COMPLETED]) as implementation progresses through each phase. Called by implementation agents at each phase boundary for real-time oversight. Keeps existing update-plan-status.sh for plan-level status (header). Integrates with skill-implementer and general-implementation-agent so phases are marked as they execute. Add logging of phase transitions for oversight.

---

### 649. Simplify state update pipeline to state.json-only with TODO.md regeneration
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 648
- **Research**: [649_simplify_state_update_pipeline/reports/01_pipeline-simplification-research.md]
- **Plan**: [649_simplify_state_update_pipeline/plans/01_pipeline-simplification.md]
- **Summary**: [649_simplify_state_update_pipeline/summaries/01_pipeline-simplification-summary.md]

**Description**: Refactor update-task-status.sh to only update state.json + plan file status + call generate-todo.sh for regeneration. Remove all TODO.md awk/sed text surgery code (Phases 2 and 3). Simplify postflight-workflow.sh to update state.json artifacts only then call generate-todo.sh. Mark link-artifact-todo.sh as deprecated (artifacts tracked only in state.json, rendered by generate-todo.sh). Update skill-base.sh functions (skill_preflight_update, skill_postflight_update, skill_link_artifacts) to use simplified pipeline. Keep old code paths temporarily as logged fallbacks during transition period. Add deprecation logging so task 652 can verify old paths are unused.

---

### 648. Create generate-todo.sh to generate entire TODO.md from state.json
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 647
- **Research**: [648_create_generate_todo_script/reports/01_generate-todo-research.md]
- **Plan**: [648_create_generate_todo_script/plans/01_generate-todo-script.md]
- **Summary**: [648_create_generate_todo_script/summaries/01_generate-todo-summary.md]

**Description**: Create a single generate-todo.sh script that produces the entire TODO.md from state.json. Generates: YAML frontmatter (next_project_number), Task Order section (absorb/call existing generate-task-order.sh logic with Kahn wave computation and topic grouping), and Tasks section with all entries properly formatted (status markers, artifact links, descriptions, effort, dependencies). Terminal tasks (completed/abandoned/expanded) included in Tasks section for history but excluded from Task Order. Add lightweight logging (timestamp, operation, success/failure) to a log file for post-validation review.

---

### 647. Enrich state.json schema to be the single complete source of truth
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [647_enrich_state_json_schema/reports/01_team-research.md]
- **Plan**: [647_enrich_state_json_schema/plans/01_enrich-state-schema.md]
- **Summary**: [647_enrich_state_json_schema/summaries/01_enrichment-summary.md]

**Description**: Add title field to all task entries in state.json (currently only project_name slug exists; human-readable titles live only in TODO.md headings). Migrate full descriptions from TODO.md where missing or truncated in state.json. Ensure all metadata needed for TODO.md generation is present: effort, task_type, dependencies, artifacts, descriptions. This makes state.json self-sufficient as the sole source of truth for generating TODO.md.

---

### 646. Harden TODO.md status updates
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [646_harden_todo_status_updates/reports/01_harden-todo-status.md]
- **Plan**: [646_harden_todo_status_updates/plans/01_harden-todo-status.md]
- **Summary**: [646_harden_todo_status_updates/summaries/01_implementation-summary.md]

**Description**: Replace brittle sed pattern matching in update-task-status.sh phase 2 with robust awk/line-number approach that does not fail silently when status text format varies

---

### 645. Fix parallel write safety for state.json
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 643
- **Research**: [645_parallel_write_safety/reports/01_parallel-write-safety.md]
- **Plan**: [645_parallel_write_safety/plans/01_parallel-write-safety.md]
- **Summary**: [645_parallel_write_safety/summaries/01_parallel-write-safety-summary.md]

**Description**: Fix parallel write safety for state.json: replace shared specs/tmp/state.json temp path with mktemp unique per write, add flock mutex around state.json write operations in update-task-status.sh to prevent last-write-wins corruption when multiple agents write concurrently

---

### 644. Add reconciliation preflight to orchestrator
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 643
- **Research**: [644_reconciliation_preflight/reports/01_reconciliation-preflight.md]
- **Plan**: [644_reconciliation_preflight/plans/01_reconciliation-preflight.md]
- **Summary**: [644_reconciliation_preflight/summaries/01_reconciliation-preflight-summary.md]

**Description**: Add reconciliation preflight to orchestrator: at the start of each /orchestrate invocation scan task directories for artifacts that exist but whose status has not been promoted, replay missed postflight to provide self-healing for crashed agents missed handoffs and interrupted sessions

---

### 643. Eliminate dual postflight ownership
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: Task 642
- **Research**: [643_eliminate_dual_postflight/reports/01_eliminate-dual-postflight.md]
- **Plan**: [643_eliminate_dual_postflight/plans/01_eliminate-dual-postflight.md]
- **Summary**: [643_eliminate_dual_postflight/summaries/01_implementation-summary.md]

**Description**: Eliminate dual postflight ownership: when orchestrator_mode=true the skill should SKIP its own skill_postflight_update and only write the handoff JSON so the orchestrator exclusively owns status transitions in state.json and TODO.md

---

### 642. Fix orchestrator_mode=false for research/plan dispatch
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Research**: [642_fix_orchestrator_mode_dispatch/reports/01_orchestrator-mode-dispatch.md]
- **Plan**: [642_fix_orchestrator_mode_dispatch/plans/01_fix-orchestrator-mode.md]
- **Summary**: [642_fix_orchestrator_mode_dispatch/summaries/01_implementation-summary.md]

**Description**: Fix orchestrator_mode=false for research/plan dispatch in skill-orchestrate/SKILL.md lines 934 and 959: change to orchestrator_mode true so handoff JSON is written and orchestrator postflight chain works for all phases not just implement

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

**Description**: Fix meta-builder-agent topic assignment: replace nonexistent keyword heuristic with interactive topic picker using active_topics + New topic option

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

**Description**: Add topic revision stage to /todo skill and New topic option to /task --sync backfill

---

### 639. Fix /orchestrate TODO.md status sync and artifact linking
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None
- **Summary**: [639_fix_orchestrate_todo_sync/summaries/01_fix-summary.md]

**Description**: Replace bash function references in skill-orchestrate/SKILL.md with explicit, standalone bash commands that the orchestrator agent can execute directly via the Bash tool. The orchestrator currently updates state.json correctly but never updates TODO.md status markers or links artifacts because it treats skill_preflight_update, skill_postflight_update, and skill_link_artifact_from_handoff as pseudocode rather than callable functions (they require source skill-base.sh which agents don't run). Changes needed in both single-task (Stages 4-5) and multi-task (Stages MT-3/MT-4) sections.

---

### 638. Fix generate-task-order.sh to create Task Order section when missing
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: agent-system
- **Dependencies**: None

**Description**: Fix generate-task-order.sh to handle the case where ## Task Order doesn't exist in TODO.md. In --update-todo mode, if the ## Task Order section is not found, INSERT it before the first ## Tasks section instead of failing with a warning. This makes the script idempotent -- it creates the section on first run and replaces it on subsequent runs. Also verify the script generates clean output matching the BimodalLogic format (waves table + topic tree, no artifact links in task order entries).

---

### 87. Investigate terminal directory change when opening neovim in wezterm
- **Effort**: TBD
- **Status**: [RESEARCHED]
- **Task Type**: neovim
- **Topic**: wezterm-notifications
- **Dependencies**: None
- **Research**: [087_investigate_wezterm_terminal_directory_change/reports/research-001.md]

**Description**: Investigate why the terminal working directory changes to a project root when opening neovim sessions in wezterm from the home directory (~). Determine whether this behavior is caused by neovim or wezterm (configured in ~/.dotfiles/config/). Identify if any functionality depends on this behavior before modifying it. Goal is to avoid changing the terminal directory unless necessary.

---

### 78. Fix Himalaya SMTP authentication failure when sending emails
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: neovim
- **Topic**: wezterm-notifications
- **Dependencies**: None
- **Research**: [078_fix_himalaya_smtp_authentication_failure/reports/research-001.md]
- **Plan**: [078_fix_himalaya_smtp_authentication_failure/plans/implementation-001.md]

**Description**: Fix Gmail SMTP authentication failure when sending emails via Himalaya (<leader>me). Error: Authentication failed: Code: 535, Enhanced code: 5.7.8, Message: Username and Password not accepted. The error occurs with TLS connection attempts and persists through multiple retry attempts. Identify and fix the root cause of the SMTP credential configuration.
