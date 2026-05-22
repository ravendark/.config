---
next_project_number: 591
---

# TODO

## Task Order

*Updated 2026-05-21. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,500,501,588,590 | -- | -- |
| 2 | 589 | 588 | wezterm-notifications |

**Grouped by Topic** (indented = must complete first):

### wezterm-notifications

588 [PLANNED] — refactor_notification_signal_stop_hook
  589 [NOT STARTED] — wezterm_artifact_colors_preflight (depends: 588)
590 [PLANNED] — fix_task_number_parsing_display

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change
500 [RESEARCHED] — add_context_fork_to_core_skills
501 [PLANNED] — optimize_team_mode_fork_cache_sharing

## Tasks

### 590. Fix task number parsing and tab display consistency
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [590_fix_task_number_parsing_display/reports/01_task-number-parsing.md]
- **Plan**: [590_fix_task_number_parsing_display/plans/01_task-number-parsing.md]

**Description**: Fix task number parsing in wezterm-task-number.sh to support multi-task syntax (/research 7, 22-24), additional commands (/spawn N, /task --recover N, /task --expand N), and prevent stale task numbers. Ensure tab always shows {N} {root} format with #{task} when applicable.

---

### 589. Expand wezterm tab colors and add preflight coloring
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: 588

**Description**: Expand wezterm tab color palette with per-artifact-type colors (report=green, plan=blue, summary=gold, error=red, needs_input=gray). Add preflight tab coloring via UserPromptSubmit hook to show in-progress states (researching, planning, implementing). Include artifact type in signal file so wezterm can distinguish. Update wezterm.lua (nix-managed at ~/.dotfiles/config/wezterm.lua).

---

### 588. Refactor notification dispatch to signal-file Stop hook pattern
- **Effort**: 3-4 hours
- **Status**: [PLANNED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [588_refactor_notification_signal_stop_hook/reports/01_signal-stop-refactor.md]
- **Plan**: [588_refactor_notification_signal_stop_hook/plans/01_signal-stop-refactor.md]

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

