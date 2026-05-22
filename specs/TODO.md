---
next_project_number: 604
---

# TODO

## Task Order

*Updated 2026-05-22. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,593,598,601 | -- | uncategorized,wezterm-notifications,workflow-refactor |
| 2 | 594,597,602 | 593,598,601 | wezterm-notifications,workflow-refactor |
| 3 | 595,596 | 593,594,598 | workflow-refactor |
| 4 | 599 | 594,595,596,597,598 | workflow-refactor |
| 5 | 600 | 599 | workflow-refactor |

**Grouped by Topic** (indented = must complete first):

### workflow-refactor

593 [NOT STARTED] — extract_shared_workflow_utilities
  594 [NOT STARTED] — refactor_workflow_skills_shared_base
    595 [NOT STARTED] — refactor_research_plan_implement_commands
      599 [NOT STARTED] — update_claudemd_extension_documentation
        600 [NOT STARTED] — revise_docs_architecture_post_refactor
    596 [NOT STARTED] — create_orchestrate_command_skill_agent
  597 [NOT STARTED] — refactor_task_revise_todo_review
598 [NOT STARTED] — progressive_disclosure_context_system

### wezterm-notifications

601 [NOT STARTED] — simplify_notification_pipeline_merge_vocabulary
  602 [NOT STARTED] — update_wezterm_dim_bright_colors

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change

## Tasks

### 601. Simplify notification pipeline and merge status vocabulary
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: wezterm-notifications
- **Dependencies**: None

**Description**: Simplify the WezTerm tab coloring and TTS notification pipeline. Merge to single lifecycle vocabulary (researching/researched/planning/planned/implementing/completed/needs_input), eliminating the artifact-type vocabulary (report/plan/summary/error). Move TTS to fire AFTER artifact linking from skill postflight instead of update-task-status.sh. Eliminate signal file mechanism entirely. Simplify Stop hook to only set needs_input for wezterm (no TTS from Stop). Consolidate TTY discovery boilerplate into shared function. Update all hook copies (4 locations), extension copies, .opencode copies, and wezterm-integration.md.

---

### 602. Update wezterm.lua dim/bright color palette and fix tab-switch clearing
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: nix
- **Topic**: wezterm-notifications
- **Dependencies**: Task #601

**Description**: Update wezterm.lua color palette for dim/bright workflow stage semantics. Research=green, plan=blue, implement=gold. DIM shade for in-progress states (researching/planning/implementing), BRIGHT/BOLD for finished states (researched/planned/completed). Fix update-status handler to only clear needs_input on tab switch, preserving lifecycle states until next command. TTS announcement format: tab-number workflow-type (e.g. tab 4 researched). WezTerm config at ~/.dotfiles/config/wezterm.lua (nix-managed, rebuild via home-manager).

---

### 603. Fix /meta pre-confirmation: move interactive flow before agent spawn
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: meta-system
- **Dependencies**: None

**Description**: Fix /meta so user confirmation happens in the foreground BEFORE spawning meta-builder-agent. Root cause: AskUserQuestion from background Agent tool calls does not reliably surface to the user. Changes: (1) meta.md: document that prompt mode MUST run AskUserQuestion before Agent delegation. (2) skill-meta SKILL.md: add pre-confirmation stage between context preparation and agent spawn -- skill proposes tasks, user selects/revises via AskUserQuestion, then passes confirmed list. (3) meta-builder-agent.md: add confirmed mode that accepts pre-validated task list and creates without re-asking; keep interactive mode for no-args /meta where agent runs foreground. (4) Update multi-task-creation-standard.md to note that confirmation must happen in foreground.

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
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593, 594, 598
- **Research**: [595_refactor_research_plan_implement_commands/reports/01_seed-research.md]

**Description**: Refactor /research, /plan, /implement commands to use shared utilities from task 593 and refactored skills from task 594. Target: each command reduced to ~150-200 lines covering only routing-only controller logic (argument docs, mode-specific behavior, extension routing table). Commands MUST NOT load Tier 3 context (agent-level context stays with agents, per four-tier model). Current commands embed agent-level context inline (full state machine logic, format specifications); these must move to Tier 3 agent context files. Add orchestrator_mode=true support: skills write .orchestrator-handoff.json when orchestrator_mode is detected in delegation context. Verify extension compatibility (nvim, nix) at each step. Reference: .claude/docs/architecture/architecture-spec.md Components 1-2.

---

### 594. Refactor workflow skills to shared base pattern
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593, 598
- **Research**: [594_refactor_workflow_skills_shared_base/reports/01_seed-research.md]

**Description**: Refactor core workflow skills to use a shared base library skill-base.sh in .claude/scripts/. The library provides 11 functions: skill_validate_input, skill_preflight_update, skill_create_postflight_marker, skill_read_artifact_number, skill_read_metadata, skill_validate_artifact, skill_postflight_update, skill_increment_artifact_number, skill_propagate_memory_candidates, skill_link_artifacts, skill_cleanup. Hook points for skill-specific logic at: Stage 4 variants (context collection, unique per skill), delegation context construction (unique fields), Stage 5 agent invocation (unique subagent_type). Target sizes: skill-researcher 558L -> 150L, skill-planner ~450L -> 130L, skill-implementer ~600L -> 200L. Depends on task 598 context budget constraints (commands must not load Tier 3 context; sonnet workers <=8K tokens, opus planners <=15K tokens). Do NOT add extension hooks in this task (save for task 599). Reference: .claude/docs/architecture/architecture-spec.md Component 2.

---

### 593. Extract shared workflow utilities module
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 592
- **Research**: [593_extract_shared_workflow_utilities/reports/01_seed-research.md]

**Description**: Extract shared workflow utilities into 4 reusable shell scripts in .claude/scripts/: (1) parse-command-args.sh — parses task numbers + flags (TASK_NUMBERS, REMAINING_ARGS, TEAM_MODE, EFFORT_FLAG, MODEL_FLAG, CLEAN_FLAG, FORCE_FLAG, FOCUS_PROMPT), eliminating ~165 lines of identical copy-paste across /research, /plan, /implement. (2) command-gate-in.sh — CHECKPOINT 1: generates SESSION_ID, looks up task in state.json, guards against terminal statuses, exports TASK_TYPE, TASK_STATUS, PROJECT_NAME, PADDED_NUM. (3) command-gate-out.sh — CHECKPOINT 2: reads .return-meta.json, applies defensive status correction. (4) postflight-workflow.sh — shared postflight eliminating ~130 lines of near-identical logic. Commands source these scripts; each command shrinks to ~150-200 lines (vs. ~500 today). Include baseline token measurement methodology to validate savings. Reference: .claude/docs/architecture/architecture-spec.md Component 1.

---

### 592. Design unified workflow architecture
- **Effort**: 3-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 591
- **Research**:
  - [592_design_unified_workflow_architecture/reports/01_seed-research.md]
  - [592_design_unified_workflow_architecture/reports/02_architecture-design.md]
- **Plan**: [592_design_unified_workflow_architecture/plans/02_architecture-design.md]
- **Summary**: [592_design_unified_workflow_architecture/summaries/02_architecture-design-summary.md]

**Description**: Design the unified workflow architecture based on research findings from task 591. Covers: (1) shared command infrastructure to eliminate ~900 lines of duplicated arg parsing, flag handling, extension routing, and GATE IN/OUT across /research, /plan, /implement. (2) Shared skill base pattern to deduplicate ~80% identical preflight/postflight across workflow skills. (3) /orchestrate state machine design: task state detection -> action selection -> agent dispatch -> handoff consumption -> loop. (4) Fork vs. subagent decision tree (fork decision matrix) for each workflow stage: forks for same-turn re-dispatch (blocker escalation, team mode), fresh subagents for sequential phases. (5) dispatch_agent() abstraction: single function encapsulating fork-vs-named-subagent decision, future-proofing against Anthropic 'named fork' API when it arrives. (6) Handoff protocol specification: structured handoff objects (200-400 tokens) replacing raw artifact injection (2000-5000 tokens). (7) Extension integration points for the new architecture, including lifecycle hook interface. (8) Nested loop resolution: orchestrator outer loop and implementer inner continuation loop must be exclusive alternatives, not nested layers.

---

### 591. Research Claude Code 2026 orchestration best practices
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: None
- **Research**: [591_research_claude_code_orchestration_practices/reports/01_team-research.md]
- **Plan**: [591_research_claude_code_orchestration_practices/plans/01_orchestration-research.md]
- **Summary**: [591_research_claude_code_orchestration_practices/summaries/01_orchestration-research-summary.md]

**Description**: Research Claude Code 2026 best practices for forking vs. subagent invocation, progressive disclosure, token-efficient context loading, and agent orchestration patterns. Audit current system (~18K lines across commands/skills/agents) for token waste, duplication hotspots, and missed opportunities. Deliverable: comprehensive report covering (1) fork cache sharing strategies, (2) progressive disclosure patterns, (3) handoff artifact design, (4) orchestration state machines, (5) specific recommendations for the 9-task refactor. Related: tasks 500, 501 partially address fork optimization and will be subsumed.

---

### 590. Fix task number parsing and tab display consistency
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [590_fix_task_number_parsing_display/reports/01_task-number-parsing.md]
- **Plan**: [590_fix_task_number_parsing_display/plans/01_task-number-parsing.md]
- **Summary**: [590_fix_task_number_parsing_display/summaries/01_task-number-parsing-summary.md]

**Description**: Fix task number parsing in wezterm-task-number.sh to support multi-task syntax (/research 7, 22-24), additional commands (/spawn N, /task --recover N, /task --expand N), and prevent stale task numbers. Ensure tab always shows {N} {root} format with #{task} when applicable.

---

### 589. Expand wezterm tab colors and add preflight coloring
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: 588
- Research: [589_wezterm_artifact_colors_preflight/reports/01_wezterm-artifact-colors.md]
- **Plan**: [589_wezterm_artifact_colors_preflight/plans/01_wezterm-artifact-colors.md]
- **Summary**: [589_wezterm_artifact_colors_preflight/summaries/01_wezterm-artifact-colors-summary.md]

**Description**: Expand wezterm tab color palette with per-artifact-type colors (report=green, plan=blue, summary=gold, error=red, needs_input=gray). Add preflight tab coloring via UserPromptSubmit hook to show in-progress states (researching, planning, implementing). Include artifact type in signal file so wezterm can distinguish. Update wezterm.lua (nix-managed at ~/.dotfiles/config/wezterm.lua).

---

### 588. Refactor notification dispatch to signal-file Stop hook pattern
- **Effort**: 3-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [588_refactor_notification_signal_stop_hook/reports/01_signal-stop-refactor.md]
- **Plan**: [588_refactor_notification_signal_stop_hook/plans/01_signal-stop-refactor.md]
- **Summary**: [588_refactor_notification_signal_stop_hook/summaries/01_signal-stop-refactor-summary.md]

**Description**: Refactor TTS and wezterm notification dispatch from agent-dependent Stage 8a calls to a reliable signal-file + Stop hook pattern. Core problem: TTS depends on agents executing lifecycle-notify.sh in Stage 8a (frequently skipped), and the Stop hook's wezterm-notify.sh overwrites lifecycle colors with needs_input. Fix: update-task-status.sh postflight writes lifecycle signal file (.claude/tmp/lifecycle-signal with status + artifact type), new unified Stop hook script reads signal and dispatches both TTS and wezterm color atomically. Remove lifecycle-notify.sh from skill Stage 8a, remove duplicate wezterm-notify.sh call from update-task-status.sh Phase 5. All 4 copies of tts-notify.sh must be updated.

---

### 587. Fix Neovim rendering corruption after system sleep in WezTerm
- **Effort**: 4-6 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Dependencies**: None
- **Research**:
  - [587_fix_neovim_rendering_after_sleep_wezterm/reports/01_neovim-sleep-rendering.md]
  - [587_fix_neovim_rendering_after_sleep_wezterm/reports/02_yanky-alternatives.md]
  - [587_fix_neovim_rendering_after_sleep_wezterm/reports/03_custom-yank-design.md]
  - [587_fix_neovim_rendering_after_sleep_wezterm/reports/04_implementation-diagnostic.md]
  - [587_fix_neovim_rendering_after_sleep_wezterm/reports/05_team-research.md]
  - [587_fix_neovim_rendering_after_sleep_wezterm/reports/06_refined-yank-design.md]
- **Plan**: [587_fix_neovim_rendering_after_sleep_wezterm/plans/06_refined-yank-ring.md]
- **Summary**: [587_fix_neovim_rendering_after_sleep_wezterm/summaries/06_refined-yank-ring-summary.md]

**Summary**: Replaced yanky.nvim with custom 4-module yank ring: ring.lua (circular buffer), highlight.lua (vim.hl.on_yank wrapper), telescope.lua (history picker), init.lua (entry point). Removed all yanky.nvim dependencies from telescope.lua, which-key.lua, and tools/init.lua. Deleted yanky.lua.

**Description**: Fix Neovim rendering corruption after system sleep in WezTerm. Primary root cause: yanky.nvim system_clipboard.sync_with_ring = true triggers a blocking wl-paste call via FocusGained on wake. On Wayland/GNOME, wl-paste can hang indefinitely when the compositor clipboard state is stale after sleep, freezing the entire Neovim TUI. Solution: replace yanky.nvim with a custom yank ring module (~460 LOC across 6 modules under lua/neotex/yank/) that uses vim.system() with a 2-second timeout for all clipboard reads. Includes post-sleep rendering recovery autocommands (mode, redraw!, treesitter invalidation). Research completed in dotfiles task 59 -- 3 research reports copied over.

---

### 586. Restrict TTS to lifecycle transitions and interactive prompts
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [586_restrict_tts_lifecycle_interactive/reports/01_restrict-tts-triggers.md]
- **Plan**: [586_restrict_tts_lifecycle_interactive/plans/01_restrict-tts-triggers.md]
- **Summary**: [586_restrict_tts_lifecycle_interactive/summaries/01_restrict-tts-triggers-summary.md]

**Description**: Restrict TTS announcements to two trigger categories only: (1) lifecycle transitions at deliverable boundaries (researched, planned, completed) and (2) interactive prompts requiring user input (permission_prompt, elicitation_dialog). Currently the Stop hook fires TTS on every Claude turn ("Tab N") and idle_prompt fires a 60-second inactivity reminder — both unwanted.

**Changes required:**

1. **`settings.json`**: Remove `tts-notify.sh` from Stop hook entries (line ~102). Change Notification matcher from `permission_prompt|idle_prompt|elicitation_dialog` to `permission_prompt|elicitation_dialog` (line ~148).

2. **`update-task-status.sh`**: Remove PHASE 5 TTS trigger (line 372 `bash tts-notify.sh --lifecycle`) and signal file write (line 366 `echo "$STATE_STATUS" > tts-lifecycle-signal`). Keep WezTerm tab color notify (line 379).

3. **Create `scripts/lifecycle-notify.sh`**: New script that calls `tts-notify.sh --lifecycle STATUS` and optionally `wezterm-notify.sh STATUS`. This is the single entry point for lifecycle TTS, called by skills after artifact linking.

4. **`tts-notify.sh`**: Remove entire "normal mode" section (lines 140-274 — stdin parsing, cooldown, signal file check, worktree detection, generic "Tab N" message). Remove signal file mechanism (check_signal_file, consume_signal_file helpers, LIFECYCLE_SIGNAL_FILE constant). Keep only lifecycle mode (lines 97-138). Remove LAST_NOTIFY_FILE cooldown since lifecycle mode already bypasses it. Update extension core copy.

5. **Skill postflight pattern**: Add "Stage 8a: Lifecycle TTS" to all delegating skills, placed AFTER Stage 8 (artifact linking) and BEFORE Stage 9 (cleanup). This ensures artifacts are already linked when TTS fires. Skills to update: skill-researcher, skill-planner, skill-implementer, skill-reviser, and extension skills (skill-neovim-research, skill-neovim-implementation, skill-nix-research, skill-nix-implementation). Stage 8a calls `scripts/lifecycle-notify.sh` with the postflight status.

6. **Documentation**: Update `tts-stt-integration.md` to reflect new trigger model (lifecycle + interactive only, no Stop hook, no idle_prompt).

---

### 500. Add context: fork frontmatter to core delegating skills
- **Effort**: 1-3 hours
- **Status**: [ABANDONED]
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
- **Status**: [ABANDONED]
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
| 1 | 586 | [NOT STARTED] | /research 586 |
| 2 | 500 | [RESEARCHED] | /plan 500 |
| 3 | 501 | [PLANNED] | /implement 501 |
| 4 | 87 | [RESEARCHED] | /plan 87 |
| 5 | 78 | [PLANNED] | /implement 78 |

---

## Recently Completed

| Task | Name | Completed |
|------|------|-----------|
| 585 | Rewrite multi-task dispatch to use parallel Skill invocation | 2026-05-16 |
| 584 | Research parallel Skill dispatch approach | 2026-05-15 |
| 583 | Port agent and skill integration | 2026-05-15 |
| 582 | Port command integration (task.md, todo.md, review.md) | 2026-05-15 |
| 581 | Port update-task-status.sh Phase 3 rewrite | 2026-05-15 |
| 580 | Port topic schema and rules | 2026-05-15 |
| 579 | Port generate-task-order.sh and task-order-format.md | 2026-05-15 |
| 578 | Fix OpenCode /tmp/ file usage root cause everywhere | 2026-05-15 |
| 577 | Investigate .opencode/ output path corruption after extension reload | 2026-05-15 |
| 576 | Fix OpenCode session picker restore/browse options | 2026-05-15 |

