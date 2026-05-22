---
next_project_number: 600
---

# TODO

## Task Order

*Updated 2026-05-22. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,591 | -- | --,workflow-refactor |
| 2 | 592 | 591 | workflow-refactor |
| 3 | 593,598 | 592 | workflow-refactor |
| 4 | 594,597 | 593,598 | workflow-refactor |
| 5 | 595,596 | 593,594,598 | workflow-refactor |
| 6 | 599 | 594,595,596,597,598 | workflow-refactor |

**Grouped by Topic** (indented = must complete first):

### workflow-refactor

591 [IMPLEMENTING] — research_claude_code_orchestration_practices
  592 [NOT STARTED] — design_unified_workflow_architecture
    593 [NOT STARTED] — extract_shared_workflow_utilities
    598 [NOT STARTED] — progressive_disclosure_context_system
      594 [NOT STARTED] — refactor_workflow_skills_shared_base
      597 [NOT STARTED] — refactor_task_revise_todo_review
        595 [NOT STARTED] — refactor_research_plan_implement_commands
        596 [NOT STARTED] — create_orchestrate_command_skill_agent
          599 [NOT STARTED] — update_claudemd_extension_documentation

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change

## Tasks

### 599. Update CLAUDE.md, extension integration, and documentation
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 594, 595, 596, 597, 598
- **Research**: [599_update_claudemd_extension_documentation/reports/01_seed-research.md]

**Description**: Update CLAUDE.md, extension integration points, and documentation for the refactored system. (1) Regenerate .claude/CLAUDE.md to reflect: new /orchestrate command, refactored command/skill/agent inventory, updated routing table, new shared utilities, progressive disclosure architecture. (2) Update extension manifest schema if integration points changed. (3) Update .claude/docs/ guides: creating-commands.md, creating-skills.md, creating-agents.md to reflect shared infrastructure patterns. (4) Update rules if workflow/checkpoint patterns changed. (5) Verify extension compatibility — ensure nvim, nix, and other loaded extensions still integrate correctly with refactored core. (6) Update system-overview.md architecture documentation.

---

### 598. Update context system for progressive disclosure and agent context budgets
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 592
- **Research**: [598_progressive_disclosure_context_system/reports/01_seed-research.md]

**Description**: Update the context system (97 index entries, ~22K lines of documentation) for progressive disclosure and agent context budgets. This task is ELEVATED in the dependency chain: progressive disclosure design informs what the shared skill base (task 594) and commands (task 595) need to support, so it must be designed before those tasks. (1) Implement tiered context loading: Level 1 (always) — minimal bootstrap (~500 lines: anti-stop-patterns, return-metadata, checkpoint-execution), Level 2 (command-specific) — loaded on command detection, Level 3 (agent-specific) — loaded at agent spawn, Level 4 (on-demand) — loaded via @-ref only when needed. (2) Add context budget metadata to index entries (estimated token cost per file, tier value). (3) Implement context budget caps per agent type: sonnet workers ~8K tokens, opus planners ~15K tokens, haiku utilities ~2K tokens. (4) Update load_when patterns to support the new tier system. (5) Audit which of the 97 entries are actually used by which agents and prune dead entries. Key insight: commands should NOT load agent-level context — the agent loads its own context; the command's job is routing only.

---

### 597. Refactor /task, /revise, /todo, /review commands for consistency
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593
- **Research**: [597_refactor_task_revise_todo_review/reports/01_seed-research.md]

**Description**: Refactor /task (710L), /revise (161L), /todo (1047L), and /review (1040L) for consistency with the new architecture from task 593. /task: Use shared utilities for state operations, reduce redundancy across 5 modes. /revise: Already compact, integrate with orchestrator handoff protocol. /todo: Decompose 1047-line monolith — extract orphan detection, roadmap sync, vault operation, and metrics into separate utility modules. Critical: add memory harvest automation — 571 archived tasks have memory_candidates in state.json but only 3 memories exist in the vault; /todo archival should automatically harvest memory candidates from tasks being archived, closing this information loss gap. /review: Decompose 1040-line monolith — extract issue grouping algorithm (180L), roadmap integration (120L), and 3-tier selection flow into reusable components.

---

### 596. Create /orchestrate command, skill, and orchestrator agent
- **Effort**: 3-4 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593, 594, 598
- **Research**: [596_create_orchestrate_command_skill_agent/reports/01_seed-research.md]

**Description**: Create the /orchestrate command, skill, and orchestrator agent. Usage: /orchestrate N [--auto]. Behavior: fire-and-forget autonomous loop — /orchestrate drives the full lifecycle (research -> plan -> implement) without confirmation gates between phases. (1) Load task state from state.json — current status, artifacts, plan phases. (2) Determine next action: if not_started -> research; if researched -> plan; if planned -> implement; if implementing/partial -> resume from handoff; if blocked -> research blocker then revise plan. (3) Fork or spawn subagents as appropriate — forks for same-turn re-dispatch when context is warm (blocker escalation), fresh subagents for sequential phase dispatch. (4) Each sub-operation writes a handoff artifact that the orchestrator reads to decide next steps without accumulating tool output in orchestrator context. (5) Blocker escalation (the highest-value capability): implementation agents flag blockers in handoff, orchestrator dispatches research fork (cache-warm, ~90% token savings), reads findings, invokes reviser, re-dispatches implementation. (6) Loop until task reaches completed status. (7) Nested loop resolution: when /orchestrate dispatches /implement, set a flag that disables skill-implementer's inner continuation loop — the orchestrator handles continuation at the outer level; the two loops must be exclusive alternatives, not nested layers. Subsumes task 501 re: fork cache optimization. Context budget architecture from task 598 informs orchestrator context management.

---

### 595. Refactor /research, /plan, /implement commands to use shared infrastructure
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593, 594, 598
- **Research**: [595_refactor_research_plan_implement_commands/reports/01_seed-research.md]

**Description**: Refactor /research (500L), /plan (531L), /implement (612L) commands to use shared utilities from task 593 and refactored skills from task 594. Target: each command reduced to ~150-200 lines covering only command-specific logic (argument docs, mode-specific behavior, output formatting). Shared infrastructure handles arg parsing, flag processing, routing, GATE IN/OUT, multi-task dispatch, and COMMIT. Context budget architecture from task 598 already defines what commands should and should not load — commands should NOT load agent-level context (agent loads its own context); the command's job is routing only. Extension compatibility: verify nvim, nix, and other loaded extensions still integrate correctly at each step, not just at task 599.

---

### 594. Refactor workflow skills to shared base pattern
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 593, 598
- **Research**: [594_refactor_workflow_skills_shared_base/reports/01_seed-research.md]

**Description**: Refactor the 4 core workflow skills (skill-researcher 558L, skill-planner 490L, skill-implementer 629L, skill-reviser 489L) to use a shared base pattern, eliminating ~80% structural duplication. All share: input validation, preflight status update, artifact number calculation, memory retrieval, format injection, agent spawning, metadata reading, validation, postflight status update, artifact linking, git commit, cleanup, return summary. Target: each skill reduced to ~100-150 lines of unique logic (agent prompt construction, skill-specific context). Design goal: extension lifecycle hooks — extensions participate in the lifecycle via manifest.json hooks (preflight, context_injection, postflight) rather than full skill duplication, as documented in task 591 team research. Context budget architecture from task 598 informs what the shared base needs to support — skills must know their context tier (sonnet workers ~8K, opus planners ~15K) to enforce budget caps. Resolves task 500 (add_context_fork_to_core_skills): fork cache sharing is incompatible with named agent routing; use forks only for same-turn re-dispatch, fresh subagents for all named-agent dispatch, encapsulated in dispatch_agent(). Team skills (skill-team-research 616L, skill-team-plan 598L, skill-team-implement 677L) should also leverage the shared base where possible.

---

### 593. Extract shared workflow utilities module
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 592
- **Research**: [593_extract_shared_workflow_utilities/reports/01_seed-research.md]

**Description**: Extract shared workflow utilities into reusable modules per the architecture from task 592. Target components: (1) parse_task_args() — multi-task number parsing with comma/range support, currently duplicated in /research, /plan, /implement (~30 lines x3). (2) Flag parsing — effort, model, clean, team flags (~50 lines x3). (3) Extension routing lookup — manifest-based task_type to skill resolution (~30 lines x3). (4) GATE IN template — preflight validation, status update, session generation. (5) GATE OUT template — postflight verification, defensive corrections, status assertion. (6) Unified postflight-workflow.sh: single parameterized script replacing 3 near-identical postflight scripts differing only in operation type (research|plan|implement), eliminating ~130 lines of duplication. (7) Shared GATE IN/OUT templates: @-referenced context files replacing copy-pasted protocol blocks, saving ~240 lines. (8) Multi-task dispatch — batch validation, parallel skill invocation, consolidated output. (9) COMMIT template — git commit with session ID. (10) Baseline token measurement methodology: measure actual per-command token cost before and after extraction to validate the refactoring achieves intended savings. These may be implemented as shared command fragments, skill utilities, or shell scripts depending on the architecture design.

---

### 592. Design unified workflow architecture
- **Effort**: 3-4 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Topic**: workflow-refactor
- **Dependencies**: 591
- **Research**: [592_design_unified_workflow_architecture/reports/01_seed-research.md]

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

