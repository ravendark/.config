---
next_project_number: 567
---

# TODO

## Task Order

*Updated 2026-05-13. 12 active tasks remaining.*

### Pending
- **564** [COMPLETED] -- Add lean agent escalation protocol and vacuous-definition prohibition (.opencode/)
- **565** [NOT STARTED] -- Add plan-compliance spot-check gate to lean skill (.opencode/) (depends: 564)
- **566** [NOT STARTED] -- Port escalation/compliance fixes to .claude/ reference system (depends: 565)
- **562** [COMPLETED] -- Upgrade consult report to interactive actionable checklist format
- **563** [RESEARCHING] -- Make /consult always create a task automatically (depends: 562)
- **560** [COMPLETED] -- Research model routing best practices for agent system
- **561** [COMPLETED] -- Implement tiered model defaults across agent system (depends: 560)
- **557** [COMPLETED] -- Research lifecycle-aware notification patterns for Claude Code hooks
- **500** [RESEARCHED] -- Add context: fork frontmatter to core delegating skills (depends: 499)
- **501** [PLANNED] -- Optimize team-mode skills for FORK_SUBAGENT parallel cache sharing (depends: 499)
- **87** [RESEARCHED] -- Investigate terminal directory change in wezterm
- **78** [PLANNED] -- Fix Himalaya SMTP authentication failure

## Tasks

### 564. Add lean agent escalation protocol and vacuous-definition prohibition (.opencode/)
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [564_lean_agent_escalation_protocol_vacuous_prohibition/reports/01_escalation-protocol-research.md]
- **Plan**: [564_lean_agent_escalation_protocol_vacuous_prohibition/plans/01_escalation-protocol-plan.md]
- **Summary**: [564_lean_agent_escalation_protocol_vacuous_prohibition/summaries/01_escalation-protocol-summary.md]
- **Description**: Add formal escalation protocol and vacuous-definition prohibition to the lean-implementation-agent in /home/benjamin/Projects/ProofChecker/.opencode/. When a phase cannot be completed properly, agent MUST mark it [BLOCKED] with documented blocker and return status partial — never create vacuous Lean definitions (def X := True, def X := Unit) to paper over inability. Also: define vacuous proof explicitly with examples, enforce phase-granular commits (commit after each phase, not batch), add task complexity warning to GATE IN for plans with >20h estimated effort.
  - **Target files**: `.opencode/agent/subagents/lean-implementation-agent.md`, `.opencode/rules/lean4.md`

### 565. Add plan-compliance spot-check gate to lean skill (.opencode/)
- **Effort**: 1-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: 564
- **Description**: Add plan-compliance spot-check gate to the .opencode/ lean skill and GATE OUT context in /home/benjamin/Projects/ProofChecker/.opencode/. Add Stage 6b to skill-lean-implementation/SKILL.md: read plan Key Theorems/Deliverables section, verify each listed theorem exists in the implementation with a non-vacuous definition body. Add delivery integrity check: if plan says implement X as replacement for Y, verify X does not call Y. Add lean4-specific verification hook to checkpoint-gate-out.md.
  - **Target files**: `.opencode/skills/skill-lean-implementation/SKILL.md`, `.opencode/context/checkpoints/checkpoint-gate-out.md`, `.opencode/context/orchestration/orchestration-validation.md`

### 566. Port escalation/compliance fixes to .claude/ reference system
- **Effort**: 1-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: 565
- **Description**: Port the escalation protocol and plan-compliance fixes from .opencode/ (tasks 564-565) to the upstream .claude/ reference system at ~/.config/nvim/.claude/. Research what lean extension files exist in .claude/extensions/lean/ and update them accordingly. Note: the .claude/ system is currently MORE trusting than .opencode/ (reads verification_passed from agent metadata without redundant check) — research findings may require different treatment or amendment to postflight-tool-restrictions.md.
  - **Target files**: `.claude/extensions/lean/` agent, skill, and rules files

### 562. Upgrade consult report to interactive actionable checklist format
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [562_consult_checklist_report_format/reports/01_consult-checklist-research.md]
- **Plan**: [562_consult_checklist_report_format/plans/01_consult-checklist-plan.md]
- **Summary**: [562_consult_checklist_report_format/summaries/01_consult-checklist-summary.md]
- **Description**: Upgrade legal-analysis-agent report format to interactive actionable checklist. Change Stage 3-6 flow so findings are presented one-at-a-time via AskUserQuestion with Accept/Reject/Modify decisions (grouped by category). After all findings, offer a revision pass, then compile the full checklist report with per-finding decision checkboxes and a summary revision checklist table.

### 563. Make /consult always create a task automatically
- **Effort**: 1-3 hours
- **Status**: [RESEARCHING]
- **Task Type**: meta
- **Dependencies**: 562
- **Description**: Update consult.md command and skill-consult to always create a task on invocation. Auto-generate task slug from input, create state.json + TODO.md entries before delegation, remove standalone/temp-file mode, display task number and next steps at Gate Out.

### 560. Research model routing best practices for agent system
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [560_research_model_routing_best_practices/reports/01_model-routing-research.md]
- **Plan**: [560_research_model_routing_best_practices/plans/01_model-routing-research.md]
- **Summary**: [560_research_model_routing_best_practices/summaries/01_model-routing-summary.md]

**Description**: Research optimal model assignments for each agent role in the .claude/ system. Analyze which agents genuinely need Opus-level reasoning vs which could default to Sonnet or inherit. Evaluate implementation agents, research agents, planner, meta-builder, spawn, reviser, and code reviewer roles. Research opusplan mode, model: inherit pattern, effort levels, and CLAUDE_CODE_SUBAGENT_MODEL integration. Produce a model assignment matrix with cost projections based on 2026 best practices.

---

### 561. Implement tiered model defaults across agent system
- **Effort**: 2-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #560
- **Research**: [561_implement_tiered_model_defaults/reports/01_tiered-model-audit.md]
- **Plan**: [561_implement_tiered_model_defaults/plans/01_tiered-model-defaults.md]
- **Summary**: [561_implement_tiered_model_defaults/summaries/01_tiered-model-defaults-summary.md]

**Description**: Based on research findings from task 560, update agent frontmatter model: fields to use appropriate model tiers. Update agent-frontmatter-standard.md, CLAUDE.md skill-agent mapping tables, command frontmatter, context references, and templates. Ensure --opus/--sonnet/--haiku runtime overrides still work. Consider model: inherit for user-controlled agents. Verify team-mode skills continue defaulting teammates to sonnet.

---

### 557. Research lifecycle-aware notification patterns for Claude Code hooks
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Task Type**: general
- **Dependencies**: None
- **Research**: [557_research_lifecycle_notification_patterns/reports/01_lifecycle-notification-patterns.md]
- **Plan**: [557_research_lifecycle_notification_patterns/plans/01_lifecycle-notification-patterns.md]
- **Summary**: [557_research_lifecycle_notification_patterns/summaries/01_lifecycle-notification-summary.md]

**Description**: Research best practices for Claude Code 2026 hook architectures, lifecycle-aware notification systems, and signal-based event patterns. Investigate: (1) Claude Code hook event model -- what data is available in Stop vs Notification vs SubagentStop stdin JSON, and whether lifecycle context can be inferred. (2) Signal file patterns vs direct invocation vs state-based approaches for coordinating postflight scripts with notification hooks. (3) Notification UX patterns for agent-based dev tools -- when to interrupt the user vs stay silent. (4) WezTerm OSC 1337 user variable best practices for multi-state indicators beyond binary needs_input. Evaluate the four candidate approaches (signal file, direct invocation, state-based, unified dispatcher) with pros/cons. Currently tts-notify.sh and wezterm-notify.sh fire on every Stop event (every Claude response), creating notification spam. They should only fire at task management lifecycle checkpoints: research report ready, plan ready, implementation done, task blocked.

---

### 500. Add context: fork frontmatter to core delegating skills
- **Effort**: 1-3 hours
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: Task #499
- **Research**:
  - [500_add_context_fork_to_core_skills/reports/01_add-context-fork-skills.md]
  - [500_add_context_fork_to_core_skills/reports/02_web-fork-best-practices.md]
  - [500_add_context_fork_to_core_skills/reports/04_hybrid-architecture-analysis.md]
- **Plan**:
  - [500_add_context_fork_to_core_skills/plans/01_add-context-fork-skills.md]
  - [500_add_context_fork_to_core_skills/plans/02_add-context-fork-skills.md]

**Description**: Based on research findings from task 499, update core delegating skills to use `context: fork` and `agent:` frontmatter fields for prompt cache efficiency. Currently only skill-meta uses `agent:` and only present-extension skills use `context: fork` -- the 8 core delegating skills (skill-researcher, skill-planner, skill-implementer, skill-reviser, skill-spawn, plus neovim-research, neovim-implementation, nix-research, nix-implementation) all delegate via explicit Task tool invocation without these fields. This creates a documentation-vs-reality gap (thin-wrapper-skill.md recommends fork+agent but core skills do not use them). Update skill frontmatter, verify subagent delegation still works correctly, update system-overview.md to reflect the new pattern, and ensure extension core copies stay synchronized.

---

### 501. Optimize team-mode skills for FORK_SUBAGENT parallel cache sharing
- **Effort**: 1-3 hours
- **Status**: [PLANNED]
- **Task Type**: meta
- **Dependencies**: Task #499
- **Research**: [501_optimize_team_mode_fork_cache_sharing/reports/01_team-mode-fork-cache.md]
- **Plan**: [501_optimize_team_mode_fork_cache_sharing/plans/01_team-mode-fork-cache.md]

**Description**: Optimize skill-team-research, skill-team-plan, and skill-team-implement to maximize CLAUDE_CODE_FORK_SUBAGENT parallel cache sharing benefits. With FORK_SUBAGENT=1, teammates 2-N sharing the parent's cached prefix get ~90% input token cost reduction. Investigate: (1) Whether teammate spawning currently inherits the prompt cache or starts fresh. (2) If restructuring teammate dispatch order or context preparation can improve cache hit rates. (3) Whether the default team_size=2 should be reconsidered given reduced costs per additional teammate. (4) Update team orchestration patterns and metadata to track cache savings.

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
| 1 | 562 | [NOT STARTED] | /research 562 |
| 2 | 563 | [NOT STARTED] | /research 563 (depends: 562) |
| 3 | 560 | [COMPLETED] | /todo |
| 4 | 561 | [COMPLETED] | /todo |
| 5 | 500 | [RESEARCHED] | /plan 500 |
| 6 | 501 | [PLANNED] | /implement 501 |
| 7 | 87 | [RESEARCHED] | /plan 87 |
| 8 | 78 | [PLANNED] | /implement 78 |

---

## Recently Completed

| Task | Name | Completed |
|------|------|-----------|
| 556 | Add literature awareness to planner, research agents, lean4 rule | 2026-05-12 |
| 555 | Update proof workflow docs with literature-first stages | 2026-05-12 |
| 554 | Create literature fidelity policy for Formal extension | 2026-05-12 |
| 553 | Create literature fidelity policy for Lean extension | 2026-05-12 |
| 551 | Fix discord-link.lua session discovery | 2026-05-09 |
| 550 | Unify Ctrl-CR toggle and agent picker | 2026-05-08 |
| 549 | Audit and relocate /tmp/ references | 2026-05-08 |
| 547 | Research mobile agent management via Discord bot | 2026-05-08 |

