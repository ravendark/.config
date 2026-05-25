---
next_project_number: 616
---

# TODO

## Task Order

*Updated 2026-05-25. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,615 | -- | orchestrate-progress |

**Grouped by Topic** (indented = depends on parent):

### Orchestrate Progress

615 [RESEARCHED] — Have the orchestrator inspect the plan file between cycles (not j

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change

## Tasks

### 613. Add structured subtask counts to orchestrator handoff
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Topic**: orchestrate-progress
- specs/613_structured_handoff_subtask_counts/reports/01_handoff-subtask-counts.md: [Research]
- specs/613_structured_handoff_subtask_counts/plans/01_handoff-subtask-plan.md: [Plan]
- specs/613_structured_handoff_subtask_counts/summaries/01_handoff-subtask-summary.md: [Summary]

**Description**: Add structured subtask completion counts to `.orchestrator-handoff.json`. Currently the handoff only contains `summary` and `status` fields. Add `phases_completed`/`phases_total` and per-phase subtask counts (`completed`/`total`) so the orchestrator knows exactly what was accomplished. Files: `general-implementation-agent.md` Stage 7 (`.return-meta.json`), `skill-implementer.md` (handoff reading), `skill-orchestrate SKILL.md` (handoff parsing).

---

### 614. Add post-phase subtask validation to implementation agents
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Topic**: orchestrate-progress
- specs/614_post_phase_subtask_validation/reports/01_subtask-validation.md: [Research]
- specs/614_post_phase_subtask_validation/plans/01_subtask-validation-plan.md: [Plan]
- specs/614_post_phase_subtask_validation/summaries/01_subtask-validation-summary.md: [Summary]

**Description**: Add lightweight post-phase validation to implementation agents that checks all `- [ ]` items in the current phase were addressed (completed, skipped with annotation, or deferred) before marking the phase `[COMPLETED]`. Currently the agent is instructed to check off items (Stage 4B-ii) but nothing validates compliance. Add a self-check step between Stage 4D (post-phase review) and Stage 5 (next phase) that counts unchecked items and either completes them or annotates why they were skipped. Files: `general-implementation-agent.md`, `neovim-implementation-agent.md`, `nix-implementation-agent.md`.

---

### 615. Add orchestrator plan inspection between cycles
- **Effort**: 1-2 hours
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: 613
- **Topic**: orchestrate-progress
- specs/615_orchestrator_plan_inspection/reports/01_plan-inspection.md: [Research]

**Description**: Have the orchestrator inspect the plan file between cycles (not just the handoff) to detect drift and decide if plan revision is needed. Currently the orchestrator only reads `.orchestrator-handoff.json` after each agent dispatch. With structured counts from task 613, add logic in `skill-orchestrate SKILL.md` to: (1) read phase completion percentages from the handoff, (2) if subtask completion < 70% in a phase, inspect the plan file for unchecked items vs. annotated deviations, (3) if significant drift detected (>30% deviations), trigger plan revision via reviser-agent before continuing. Files: `skill-orchestrate SKILL.md` (post-dispatch logic, lines 306-327).

---

### 612. Sync missing scripts to core extension for loader deployment
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [612_sync_missing_scripts_to_core_extension/reports/01_script-sync-research.md]
- **Plan**: [612_sync_missing_scripts_to_core_extension/plans/01_script-sync-plan.md]
- **Summary**: [612_sync_missing_scripts_to_core_extension/summaries/01_script-sync-summary.md]

**Description**: 18 scripts in `.claude/scripts/` are missing from `.claude/extensions/core/scripts/` and the core manifest `provides.scripts` array. This causes the `<leader>al` loader to not copy them to other projects, breaking all commands (which reference `command-gate-in.sh`, `parse-command-args.sh`, `skill-base.sh`, etc). Fix: copy the 18 missing scripts to the extension source directory and add them to `manifest.json`. Critical missing: `command-gate-in.sh`, `command-gate-out.sh`, `command-route-skill.sh`, `parse-command-args.sh`, `skill-base.sh`, `dispatch-agent.sh`, `generate-task-order.sh`, `archive-task.sh`, `vault-operation.sh`, `roadmap-sync.sh`, `roadmap-integration.sh`, `memory-harvest.sh`, `orphan-detection.sh`, `issue-grouping.sh`, `postflight-workflow.sh`, `rename-session.sh`, `tier-selection.sh`, `validate-context-budgets.sh`.

---

### 611. Add optional prompt parameter to /orchestrate command
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Report**: [specs/611_add_prompt_to_orchestrate/reports/01_prompt-parameter-research.md]
- **Plan**: [611_add_prompt_to_orchestrate/plans/01_prompt-parameter-plan.md]
- **Summary**: [611_add_prompt_to_orchestrate/summaries/01_prompt-parameter-summary.md]

**Description**: Add optional prompt parameter to /orchestrate command. Current syntax: `/orchestrate N`. New syntax: `/orchestrate N [prompt]`. The prompt flows through the delegation chain: command parses args into task_number + prompt, includes prompt in delegation context JSON, skill extracts prompt and propagates to each sub-agent dispatch (research, plan, implement). Files to modify: `.claude/commands/orchestrate.md`, `.claude/extensions/core/commands/orchestrate.md`, `.claude/skills/skill-orchestrate/SKILL.md`, `.claude/CLAUDE.md` command reference.

---

### 608. Define context-protective lead pattern
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [608_context_protective_lead_pattern/reports/01_context-protective-lead.md]
- **Plan**: [608_context_protective_lead_pattern/plans/01_context-protective-plan.md]
- **Summary**: [608_context_protective_lead_pattern/summaries/01_context-protective-summary.md]

**Description**: Create a pattern document and standard that establishes how lead/orchestrator agents should protect their context window. Core principles: (1) never Read large files directly — use jq/Bash one-liners to extract specific fields, (2) fork cheap investigation agents when in-depth information is needed, receiving back short reports (<200 words), (3) lead's context budget target: <10k tokens above baseline for routing and delegation work. Document anti-patterns (reading full state.json, loading format specs, eagerly reading context files) and the correct alternatives (jq extraction, scout forks, passing @-references to subagents instead of reading them yourself). This becomes the reference standard for tasks 609 and 610.

---

### 609. Refactor skill-team-research for context protection
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: 608
- **Research**:
  - [609_refactor_team_research_context_protection/reports/01_context-protection-research.md]
  - [609_refactor_team_research_context_protection/reports/02_synthesis-architecture-analysis.md]
- **Plan**: [609_refactor_team_research_context_protection/plans/01_context-protection-plan.md]
- **Summary**: [609_refactor_team_research_context_protection/summaries/01_context-protection-summary.md]

**Description**: Refactor skill-team-research (currently 751 lines, ~3,900 tokens) as the reference implementation of the context-protective lead pattern from task 608. Replace direct Read operations with jq extractions for state.json lookups. Replace eager context loading (index.json queries, domain context reads, memory retrieval) with fork agents that investigate and return compact summaries. Replace inline teammate output reading with a fork "synthesis agent" that reads all findings and writes the unified report. Target: lead's added context stays under 10k tokens beyond baseline, down from current ~50-60k. The skill file itself should also shrink by moving stage documentation to reference files.

---

### 610. Apply context-protective pattern to remaining skills
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: 608, 609
- **Research**: [610_sweep_skills_context_protection/reports/01_team-research.md]
- **Plan**: [610_sweep_skills_context_protection/plans/01_context-protection-plan.md]
- **Summary**: [610_sweep_skills_context_protection/summaries/01_context-protection-summary.md]

**Description**: Sweep all remaining skills that accumulate excessive lead context and apply the context-protective lead pattern from task 608, using task 609's refactored skill-team-research as the reference implementation. Priority targets: skill-researcher (242 lines — reads report-format.md, memory, state.json), skill-implementer (363 lines), skill-planner (215 lines), skill-orchestrator (128 lines — reads full state.json and TODO.md), skill-team-plan (598 lines), skill-team-implement (677 lines). For each skill: replace direct file reads with jq extractions, delegate investigation to fork agents, pass format references to subagents instead of reading them into the lead.

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

