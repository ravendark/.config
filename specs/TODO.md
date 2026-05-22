---
next_project_number: 605
---

# TODO

## Task Order

*Updated 2026-05-22. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,597,598,602 | -- | wezterm-notifications, workflow-refactor |
| 2 | 595,596 | 598 | workflow-refactor |
| 3 | 599 | 595,596,597,598 | workflow-refactor |
| 4 | 600 | 599 | workflow-refactor |

**Grouped by Topic** (indented = depends on parent):

### Wezterm Notifications

602 [PLANNED] — Update wezterm.lua color palette for dim/bright workflow stage se

### Workflow Refactor

597 [NOT STARTED] — Refactor /task, /revise, /todo, /review for consistency with the 
  └─ 599 [NOT STARTED] — Update CLAUDE.md, extension manifest schema, and documentation fo
    └─ 600 [NOT STARTED] — After tasks 592-599 complete, revise .claude/docs/ to reflect the
598 [NOT STARTED] — Update the context system for progressive disclosure and agent co
  └─ 595 [IMPLEMENTING] — Refactor /research, /plan, /implement commands to use shared util
    └─ 599 [NOT STARTED] — Update CLAUDE.md, extension manifest schema, and documentation fo (see above)
  └─ 596 [NOT STARTED] — Create the /orchestrate command, skill-orchestrate, and dispatch-
    └─ 599 [NOT STARTED] — Update CLAUDE.md, extension manifest schema, and documentation fo (see above)
  └─ 599 [NOT STARTED] — Update CLAUDE.md, extension manifest schema, and documentation fo (see above)

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change

## Tasks

### 602. Update wezterm.lua dim/bright color palette and fix tab-switch clearing
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: nix
- **Topic**: wezterm-notifications
- **Dependencies**: Task #601
- **Plan**: [602_update_wezterm_dim_bright_colors/plans/01_wezterm-dim-bright-colors.md]

**Description**: Update wezterm.lua color palette for dim/bright workflow stage semantics. Research=green, plan=blue, implement=gold. DIM shade for in-progress states (researching/planning/implementing), BRIGHT/BOLD for finished states (researched/planned/completed). Fix update-status handler to only clear needs_input on tab switch, preserving lifecycle states until next command. TTS announcement format: tab-number workflow-type (e.g. tab 4 researched). WezTerm config at ~/.dotfiles/config/wezterm.lua (nix-managed, rebuild via home-manager).

---

### 600. Revise .claude/docs/ architecture and guides post-refactor
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 599

**Description**: After tasks 592-599 complete, revise .claude/docs/ to reflect the refactored agent system. Primary targets: (1) system-overview.md — update to describe new unified workflow architecture. (2) docs/README.md — update index to reference new architecture documents. (3) Guides — update creating-commands.md, creating-skills.md, creating-agents.md. (4) Reference docs — update agent-frontmatter-standard.md, multi-task-creation-standard.md. (5) Templates — update to use shared base patterns. (6) Deprecate docs that describe pre-refactor architecture exclusively.

---

### 599. Update CLAUDE.md, extension integration, and documentation
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 594, 595, 596, 597, 598
- **Research**: [599_update_claudemd_extension_documentation/reports/01_seed-research.md]

**Description**: Update CLAUDE.md, extension manifest schema, and documentation for the refactored system. Extension lifecycle hooks: add hooks schema to manifest.json for all extensions: hooks.preflight, hooks.context_injection, hooks.postflight, hooks.verification. Each hook receives: $1=task_number, $2=task_type, $3=task_dir, $4=session_id, $5=operation. Hook invocation points in skill-base.sh: Stage 2 (preflight), Stage 4 (context_injection), Stage 6a (verification), Stage 7 (postflight). Thin extension skills to 30-50 lines (vs. 400-600 today): Stage 4 context injection + Stage 5 subagent invocation. Update .claude/docs/ guides: creating-commands.md, creating-skills.md, creating-agents.md. Regenerate CLAUDE.md to add /orchestrate command, routing table updates, shared utilities inventory. Update system-overview.md to reflect completed refactored architecture. Reference: .claude/docs/architecture/architecture-spec.md Component 6.

---

### 598. Update context system for progressive disclosure and agent context budgets
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 592
- **Research**: [598_progressive_disclosure_context_system/reports/01_seed-research.md]

**Description**: Update the context system for progressive disclosure and agent context budget caps. Four-tier loading model: Tier 1 (always, ~500L: anti-stop-patterns, return-metadata, checkpoint-execution), Tier 2 (command-specific, ~500L: routing tables, arg docs, anti-bypass), Tier 3 (agent-specific, ~3-5K lines: workflow patterns, domain context), Tier 4 (on-demand, unbounded: guides, templates, examples). Budget caps: sonnet workers <=8K tokens, opus planners <=15K tokens, haiku utilities <=2K tokens. Audit 97 context index entries for tier classification; prune dead entries. Commands MUST NOT load Tier 3 context (routing only). Move embedded agent context from commands to Tier 3 agent context files. This task is ELEVATED in dependency chain: context budget design must precede task 594 (skill base). Reference: .claude/docs/architecture/architecture-spec.md cross-cutting context section.

---

### 597. Refactor /task, /revise, /todo, /review commands for consistency
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593
- **Research**: [597_refactor_task_revise_todo_review/reports/01_seed-research.md]

**Description**: Refactor /task, /revise, /todo, /review for consistency with the new architecture from task 593. /task (710L): Use shared gate-in/gate-out scripts from task 593 for state operations; reduce redundancy across 5 modes. /revise (161L): Integrate with orchestrator handoff protocol (write .orchestrator-handoff.json when orchestrator_mode=true in delegation context). /todo (1047L): Decompose into utility modules: orphan detection, roadmap sync, vault operation, metrics. Critical: add memory harvest automation — harvest memory_candidates from tasks being archived (571 archived tasks have candidates but vault has only 3 memories). /review (1040L): Decompose into reusable components: issue grouping algorithm (180L), roadmap integration (120L), 3-tier selection flow. References: .claude/docs/architecture/architecture-spec.md Components 1-2 for gate-in/gate-out patterns.

---

### 596. Create /orchestrate command, skill, and orchestrator agent
- **Effort**: 3-4 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593, 594, 598
- **Research**: [596_create_orchestrate_command_skill_agent/reports/01_seed-research.md]

**Description**: Create the /orchestrate command, skill-orchestrate, and dispatch-agent.sh. File layout: .claude/commands/orchestrate.md (entry point ~50L), .claude/skills/skill-orchestrate/SKILL.md (state machine ~200L), .claude/scripts/dispatch-agent.sh (dispatch function). State machine: not_started->research->plan->implement->completed; partial+handoff->re-dispatch-implement; partial+blockers->blocker-escalation; MAX_CYCLES=5 with loop guard file (specs/{NNN}_{SLUG}/.orchestrator-loop-guard). dispatch_agent() signature: dispatch_agent agent_type prompt context_json is_blocker_escalation; is_blocker_escalation=true uses fork (no subagent_type, cache-warm ~90% savings); false uses named subagent. .orchestrator-handoff.json schema: phase, status, summary (<=100 tokens), artifacts, blockers, next_action_hint, files_modified, decisions_made, dead_ends, continuation_context; total <=400 tokens. Nested loop resolution: orchestrator_mode=true in delegation context disables skill-implementer inner continuation loop (max_continuations=0); orchestrator handles continuation externally. References: .claude/docs/architecture/orchestrate-state-machine.md, .claude/docs/architecture/dispatch-agent-spec.md, .claude/docs/architecture/handoff-schema.md.

---

### 595. Refactor /research, /plan, /implement commands to use shared infrastructure
- **Effort**: 2-3 hours
- **Status**: [IMPLEMENTING]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593, 594, 598
- **Research**:
  - [595_refactor_research_plan_implement_commands/reports/01_seed-research.md]
  - [595_refactor_research_plan_implement_commands/reports/02_command-refactor-research.md]
- **Plan**: [595_refactor_research_plan_implement_commands/plans/02_command-refactor-plan.md]

**Description**: Refactor /research, /plan, /implement commands to use shared utilities from task 593 and refactored skills from task 594. Target: each command reduced to ~150-200 lines covering only routing-only controller logic (argument docs, mode-specific behavior, extension routing table). Commands MUST NOT load Tier 3 context (agent-level context stays with agents, per four-tier model). Current commands embed agent-level context inline (full state machine logic, format specifications); these must move to Tier 3 agent context files. Add orchestrator_mode=true support: skills write .orchestrator-handoff.json when orchestrator_mode is detected in delegation context. Verify extension compatibility (nvim, nix) at each step. Reference: .claude/docs/architecture/architecture-spec.md Components 1-2.

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

## Recommended Order

| Priority | Task | Status | Next Action |
|----------|------|--------|-------------|
| 1 | 586 | [NOT STARTED] | /research 586 |
| 2 | 500 | [RESEARCHED] | /plan 500 |
| 3 | 501 | [PLANNED] | /implement 501 |
| 4 | 87 | [RESEARCHED] | /plan 87 |
| 5 | 78 | [PLANNED] | /implement 78 |

---

## Recently Completed

| Task | Name | Completed |
|------|------|-----------|
| 605 | Reverse Task Order tree direction | 2026-05-22 |
| 604 | Add Task Order regeneration to task-creating commands | 2026-05-22 |
| 603 | Fix /meta pre-confirmation pattern | 2026-05-22 |
| 601 | Simplify notification pipeline and merge vocabulary | 2026-05-22 |
| 594 | Refactor workflow skills to shared base pattern | 2026-05-22 |
| 593 | Extract shared workflow utilities | 2026-05-22 |
| 592 | Design unified workflow architecture | 2026-05-22 |
| 591 | Research Claude Code orchestration practices | 2026-05-22 |
| 590 | Fix task number parsing and tab display | 2026-05-22 |
| 589 | Expand wezterm tab colors and preflight | 2026-05-22 |
| 588 | Refactor notification dispatch to signal-file | 2026-05-22 |
| 587 | Fix Neovim rendering corruption after sleep | 2026-05-21 |
| 586 | Restrict TTS to lifecycle and interactive | 2026-05-16 |

