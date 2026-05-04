---
next_project_number: 530
---

# TODO

## Task Order

*Updated 2026-05-04. 7 active tasks remaining.*

### Pending

- **528** [NOT STARTED] -- Update skill-implementer continuation loop and pattern documentation (depends: 527)
- **527** [NOT STARTED] -- Update handoff artifact naming convention in format specs and agent definitions
- **523** [RESEARCHED] -- Change `<leader>lb` bibexport to show notification instead of terminal buffer
- **500** [RESEARCHED] -- Add context: fork frontmatter to core delegating skills (depends: 499)
- **501** [PLANNED] -- Optimize team-mode skills for FORK_SUBAGENT parallel cache sharing (depends: 499)
- **87** [RESEARCHED] -- Investigate terminal directory change in wezterm
- **78** [PLANNED] -- Fix Himalaya SMTP authentication failure

## Tasks

### 529. Fix 'Model not found: opus/' error in .opencode/ agent system after porting from .claude/
- **Status**: [IMPLEMENTING]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [529_fix_opencode_model_not_found_opus_error/reports/01_model-not-found-research.md]
- **Plan**: [529_fix_opencode_model_not_found_opus_error/plans/01_fix-model-references.md]

**Description**: The .opencode/ agent system has "opus/" model references (with trailing slash) that were accidentally ported from the .claude/ system. When using the `<leader>al` picker and running commands in projects like ProofChecker, this produces a 'Model not found: opus/' error. Systematically audit and fix all occurrences of this artifact across .opencode/ core/ and extensions/.

---

### 523. Change `<leader>lb` bibexport to show notification instead of terminal buffer
- **Effort**: < 1 hour
- **Status**: [RESEARCHED]
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [523_change_leader_lb_bibexport_notification/reports/01_bibexport-notification-research.md]

**Description**: Modify the `run_bibexport()` function in `after/ftplugin/tex.lua` to run `bibexport` asynchronously via `vim.system()` or `vim.fn.jobstart()` instead of opening a terminal buffer. On completion, display a brief notification via `vim.notify()` or `require('neotex.util.notifications')` indicating success (with output file path) or failure (with error message). This matches the pattern used by `<leader>Tr` and `<leader>Ts` template copy functions.

Key files: `after/ftplugin/tex.lua`

---

### 526. Port lean extension to `.claude/` for parity
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T15:30:00Z
- **Task Type**: meta
- **Dependencies**: Task #525
- **Research**: [526_port_lean_extension_to_claude/reports/01_lean-port-research.md]
- **Plan**: [526_port_lean_extension_to_claude/plans/01_lean-port-plan.md]
- **Summary**: [526_port_lean_extension_to_claude/summaries/01_lean-port-summary.md]

**Description**: Create `.claude/extensions/lean/` mirroring the `.opencode/extensions/lean/` structure for feature parity. Copy and adapt the lean extension manifest, agents (`lean-research-agent.md`, `lean-implementation-agent.md`), skills (`skill-lean-research/`, `skill-lean-implementation/`), and context files to the `.claude/` extension directory. Update any `.opencode/` specific references to `.claude/` equivalents. This ensures that the Claude Code agent system has the same lean4 support as OpenCode.

Key files: `.claude/extensions/lean/manifest.json`, `.claude/extensions/lean/agents/`, `.claude/extensions/lean/skills/`, `.claude/extensions/lean/context/`

---

### 528. Update skill-implementer continuation loop and pattern documentation
- **Effort**: < 1 hour
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: Task #527

**Description**: Update `skill-implementer/SKILL.md` example paths in the continuation loop documentation and Stage 7 partial handling to use the new `MM_HH_{handoff-slug}.md` naming convention. Update `subagent-continuation-loop.md` and `context-exhaustion-detection.md` pattern documents with new example `handoff_path` values. Sync all changes to `.opencode/extensions/core/` mirrors.

Key files: `.opencode/skills/skill-implementer/SKILL.md`, `.opencode/context/patterns/subagent-continuation-loop.md`, `.opencode/context/patterns/context-exhaustion-detection.md`

---

### 527. Update handoff artifact naming convention in format specs and agent definitions
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: None

**Description**: Update the handoff artifact system to use the `MM_HH_{handoff-slug}.md` naming convention where MM is the plan artifact number and HH is the handoff artifact number. Update `handoff-artifact.md` format spec with the new naming convention and slug generation guidelines (derive from phase name + current objective, kebab-case). Update `general-implementation-agent.md` Stage 4C to construct filenames using `artifact_number` (MM), `handoff_count+1` (HH, zero-padded to 2 digits), and auto-generated slug. Update extension/core/ mirrors and `lean-implementation-agent.md` references.

Key files: `.opencode/context/formats/handoff-artifact.md`, `.opencode/agent/subagents/general-implementation-agent.md`, `.opencode/extensions/lean/agents/lean-implementation-agent.md`

---

### 525. Fix lean skill path and field references
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T15:00:00Z
- **Task Type**: meta
- **Dependencies**: Task #524
- **Research**: [525_fix_lean_skill_path_field_refs/reports/01_lean-skill-audit.md]
- **Plan**: [525_fix_lean_skill_path_field_refs/plans/01_lean-skill-fix-plan.md]
- **Summary**: [525_fix_lean_skill_path_field_refs/summaries/01_lean-skill-fix-summary.md]

**Description**: Update `skill-lean-research/SKILL.md` and `skill-lean-implementation/SKILL.md` in `.opencode/extensions/lean/skills/` to fix two issues: (1) Path references use `specs/OC_${padded_num}_...` but the actual system uses `specs/${padded_num}_...` (no `OC_` prefix). (2) The skills check `.language` field but the commands route by `.task_type` — the skills should check `task_type` for consistency with the rest of the system. Also verify that other references in the lean extension (agents, context) are consistent.

Key files: `.opencode/extensions/lean/skills/skill-lean-research/SKILL.md`, `.opencode/extensions/lean/skills/skill-lean-implementation/SKILL.md`, `.opencode/extensions/lean/agents/lean-research-agent.md`, `.opencode/extensions/lean/agents/lean-implementation-agent.md`

---

### 524. Fix lean extension manifest routing
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T14:00:00Z
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [524_fix_lean_extension_manifest_routing/reports/01_manifest-routing-research.md]
- **Plan**: [524_fix_lean_extension_manifest_routing/plans/01_manifest-routing-plan.md]
- **Summary**: [524_fix_lean_extension_manifest_routing/summaries/01_manifest-routing-summary.md]

**Description**: Add the missing `routing` section to `.opencode/extensions/lean/manifest.json`. The command files (`/implement`, `/research`, `/plan`) dynamically look up routing from extension manifests using `jq -r --arg tt "$task_type" '.routing.implement[$tt] // empty'`. The lean manifest currently has no `routing` section, causing all lean tasks to fall through to defaults (`skill-implementer` → `general-implementation-agent`). Add routing mappings for `research`, `plan`, and `implement` phases mapping `lean`/`lean4` task types to the appropriate lean-specific skills. Follow the pattern used by `.opencode/extensions/nvim/manifest.json`.

Key files: `.opencode/extensions/lean/manifest.json`

---

### 518. Unified AI tool picker with two-stage session management
- **Effort**: 1-3 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T04:30:13Z
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [518_unified_ai_tool_picker_session_management/reports/02_synthesized-research.md]
- **Plan**: [518_unified_ai_tool_picker_session_management/plans/01_unified-ai-picker.md]
- **Summary**: [518_unified_ai_tool_picker_session_management/summaries/01_unified-ai-picker-summary.md]

**Description**: Create a unified two-stage Telescope picker triggered by `<C-CR>` that replaces the current separate `<C-CR>` (Claude Code) and `<C-g>` (OpenCode) keybindings. Stage 1 presents a tool picker (Claude Code vs OpenCode) that remembers the last selection and shows it first via a JSON file in `vim.fn.stdpath("data")`. Stage 2 presents a session management picker (new session, restore last session, browse all sessions) adapted to the selected tool. For Claude Code, reuse the existing `show_session_picker` logic from `claude/core/session.lua`. For OpenCode, build an equivalent using `opencode.toggle()`, `opencode.command("session.new")`, and `opencode.command("session.list")`. If an active Claude Code or OpenCode terminal is already visible, `<C-CR>` should toggle it directly (matching current smart_toggle behavior) rather than showing the picker. Remove the global `<C-g>` binding (keep the buffer-local `<C-g>` in opencode terminals for quick toggle). Update `keymaps.lua` header comments and `docs/MAPPINGS.md`.

Key files: `lua/neotex/plugins/ai/shared/picker/`, `lua/neotex/config/keymaps.lua`, `lua/neotex/plugins/ai/claude/core/session.lua`, `lua/neotex/plugins/editor/which-key.lua`

---

### 519. Add <leader>al AI commands loader picker
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [519_add_leader_al_ai_commands_loader_picker/reports/01_commands-loader-picker.md]
- **Plan**: [519_add_leader_al_ai_commands_loader_picker/plans/01_commands-loader-picker.md]
- **Summary**: [519_add_leader_al_ai_commands_loader_picker/summaries/01_commands-loader-picker-summary.md]

**Description**: Add `<leader>al` keymap that opens a unified picker (Claude Code vs OpenCode, last-used-first ordering) routing to their respective commands/extension pickers — what `<leader>ac` (ClaudeCommands) and `<leader>ao` (OpencodeCommands) do currently. Reuses task 518's `ai-tool-picker.lua` persistence infrastructure and `vim.ui.select` pattern. Handles both normal mode (commands browser) and visual mode (send selection with prompt).

Key files: `lua/neotex/plugins/ai/shared/picker/ai-tool-picker.lua`, `lua/neotex/plugins/editor/which-key.lua`

---

### 517. Fix MCP tools unavailable in opencode for Lean tasks
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: general
- **Research**: [517_fix_opencode_mcp_tools_unavailable_lean/reports/01_opencode-mcp-tools.md]
- **Plan**: [517_fix_opencode_mcp_tools_unavailable_lean/plans/01_opencode-mcp-config.md]
- **Summary**: [517_fix_opencode_mcp_tools_unavailable_lean/summaries/01_opencode-mcp-config-summary.md]

**Description**: Fix MCP tools (lean-lsp) being unavailable when using opencode to implement Lean tasks. The model attempts to call mcp__lean-lsp__lean_goal but gets error "Model tried to call unavailable tool 'mcp__lean-lsp__lean_goal'. Available tools: invalid, bash, read, glob, grep, edit, write, webfetch, websearch, codesearch, skill." The MCP servers need to be made available to opencode so that Lean LSP tools (lean_goal, lean_diagnostic_messages, lean_hover_info, etc.) work during implementation.

### 516. Remove claudemd_suggestions feature from /todo and implementation pipeline
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Research**: [516_remove_claudemd_suggestions_feature/reports/01_claudemd-suggestions-removal.md]
- **Plan**: [516_remove_claudemd_suggestions_feature/plans/01_claudemd-suggestions-removal.md]
- **Summary**: [516_remove_claudemd_suggestions_feature/summaries/01_claudemd-suggestions-summary.md]

**Description**: Remove the claudemd_suggestions feature from the task system. CLAUDE.md is now auto-generated, so the pattern of meta tasks proposing CLAUDE.md edits via claudemd_suggestions (collected during /implement and applied interactively during /todo) is obsolete. Remove: (1) claudemd_suggestions field handling from skill-implementer postflight (Stage 7 Step 3), (2) Step 3.6 (Scan Meta Tasks for CLAUDE.md Suggestions) from /todo command, (3) Step 5.6 (Interactive CLAUDE.md Suggestion Selection) from /todo command, (4) claudemd_suggestions field from state.json schema documentation, (5) Related dry-run output sections. Keep completion_summary and roadmap_items fields (those are still used).

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

**Description**: Optimize skill-team-research, skill-team-plan, and skill-team-implement to maximize CLAUDE_CODE_FORK_SUBAGENT parallel cache sharing benefits. With FORK_SUBAGENT=1, teammates 2-N sharing the parent's cached prefix get ~90% input token cost reduction. Investigate: (1) Whether teammate spawning currently inherits the prompt cache or starts fresh. (2) If restructuring teammate dispatch order or context preparation can improve cache hit rates. (3) Whether the default team_size=2 should be reconsidered given reduced costs per additional teammate. (4) Update team orchestration patterns and metadata to track cache savings. Files: `.claude/skills/skill-team-research/SKILL.md`, `.claude/skills/skill-team-plan/SKILL.md`, `.claude/skills/skill-team-implement/SKILL.md`, `.claude/context/patterns/team-orchestration.md`.

---

### 495. Add multi-subagent continuation loop to skill-implementer
- **Effort**: 3-6 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T14:00:00Z
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [495_multi_subagent_continuation_loop/reports/01_continuation-research.md]
- **Plan**: [495_multi_subagent_continuation_loop/plans/01_continuation-plan.md]
- **Summary**: [495_multi_subagent_continuation_loop/summaries/01_continuation-summary.md]

**Description**: Modify skill-implementer to detect partial/handoff returns from the implementation subagent and re-spawn new subagents to continue work. Wire the existing handoff-artifact.md and progress-file.md formats into general-implementation-agent so it writes structured handoffs before context exhaustion instead of simply returning "partial". Add a continuation loop in skill-implementer that reads the handoff artifact, injects it into a new subagent prompt, and continues spawning subagents until all phases are complete or a blocker/critical decision requires user input. The only appropriate causes for interrupting work are blockers or critical decisions -- context exhaustion should be handled transparently via handoff and re-spawn. Files: `.claude/skills/skill-implementer/SKILL.md`, `.claude/agents/general-implementation-agent.md`, `.claude/context/formats/handoff-artifact.md`, `.claude/context/formats/progress-file.md`.

---

### 496. Add prior-implementation context injection to /research
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T14:00:00Z
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [496_prior_implementation_context_injection/reports/01_prior-context-research.md]
- **Plan**: [496_prior_implementation_context_injection/plans/01_prior-context-plan.md]
- **Summary**: [496_prior_implementation_context_injection/summaries/01_prior-context-summary.md]

**Description**: Modify skill-researcher preflight to detect when a task is in [IMPLEMENTING] or [PARTIAL] status and collect existing implementation artifacts (summaries, handoffs, progress files) from the task directory. Inject these as tagged context into the research agent prompt so it understands what was already done, what approaches were tried, what failed, and where work stalled. Update general-research-agent Stage 2 to use this prior-implementation context in its search strategy, focusing research on the gaps and blockers identified in the handoffs rather than starting from scratch. Files: `.claude/skills/skill-researcher/SKILL.md` (new Stage 4d), `.claude/agents/general-research-agent.md` (Stage 2 strategy update).

---

### 497. Add per-phase plan item check-off to implementation agent
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T15:00:00Z
- **Task Type**: meta
- **Dependencies**: Task #495
- **Research**: [497_per_phase_plan_item_checkoff/reports/01_checkoff-research.md]
- **Plan**: [497_per_phase_plan_item_checkoff/plans/01_checkoff-plan.md]
- **Summary**: [497_per_phase_plan_item_checkoff/summaries/01_checkoff-summary.md]

**Description**: Extend general-implementation-agent Stage 4 (Execute File Operations Loop) to, after completing each phase, parse the plan for individual checklist items, steps, or sub-tasks within that phase and mark them as completed (using `- [x]` check-off syntax or adding brief completion notes). This provides granular visibility into what was accomplished within each phase, aids handoff documents in knowing exactly where work stopped, and helps subsequent /research runs understand partial completion state. Depends on task 495 because the handoff mechanism determines what the "completion" tracking needs to feed into. Files: `.claude/agents/general-implementation-agent.md` (Stage 4C/4D enhancement).

---

### 498. Make /spawn work from any non-terminal state with interactive confirmation
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T14:00:00Z
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [498_spawn_any_state_interactive/reports/01_spawn-state-research.md]
- **Plan**: [498_spawn_any_state_interactive/plans/01_spawn-state-plan.md]
- **Summary**: [498_spawn_any_state_interactive/summaries/01_spawn-any-state-summary.md]

**Description**: Update spawn.md to remove the restriction blocking `researching` and `planning` statuses -- /spawn should work for any task in any non-terminal state (not just blocked/implementing/partial). Update spawn-agent to work without a blocker-focused analysis when the task is not actually blocked: instead, analyze the task holistically and present the user with interactive questions (AskUserQuestion) to confirm what tasks to spawn and provide feedback or discussion before creation. The agent should ask the user about their intent, propose task decomposition, and allow iterative refinement before committing to task creation. Files: `.claude/commands/spawn.md` (status validation table), `.claude/skills/skill-spawn/SKILL.md` (preflight status handling), `.claude/agents/spawn-agent.md` (analysis mode for non-blocked tasks, interactive confirmation).

---

### 522. Fix remaining Claude Code path references in OpenCode files
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T14:00:00Z
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [522_fix_claude_code_references_opencode/reports/01_claude-refs-audit.md]
- **Plan**: [522_fix_claude_code_references_opencode/plans/01_fix-refs-plan.md]
- **Summary**: [522_fix_claude_code_references_opencode/summaries/01_fix-refs-summary.md]

**Description**: Find and replace remaining `.claude/` path references and "Claude Code" brand text in `.opencode/` files that should be `.opencode/` and "OpenCode". Update extension/core mirrors. Fix stale references like "Claude Code discovers these skills via extension manifest" in `implement.md` and `.claude/context/` references in extension/core mirrors. Also ensure `.claude/scripts/` references point to `.opencode/scripts/` where appropriate.

Key files: `.opencode/commands/implement.md`, `.opencode/context/core/`, `.opencode/context/extension/`, `.opencode/skills/`, `.opencode/docs/`

---

### 521. Add model: opus to OpenCode command frontmatter
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T14:00:00Z
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [521_add_model_opus_opencode_commands/reports/01_command-frontmatter-audit.md]
- **Plan**: [521_add_model_opus_opencode_commands/plans/01_add-model-plan.md]
- **Summary**: [521_add_model_opus_opencode_commands/summaries/01_add-model-summary.md]

**Description**: Add `model: opus` to YAML frontmatter of all `.opencode/commands/*.md` files missing it. All Claude Code commands declare `model: opus` in their frontmatter. OpenCode commands (`research.md`, `plan.md`, `implement.md`, `review.md`, `errors.md`, `refresh.md`) are missing this field, despite the agent frontmatter standard requiring it. Update the command template reference if needed.

Key files: `.opencode/commands/research.md`, `.opencode/commands/plan.md`, `.opencode/commands/implement.md`, `.opencode/commands/review.md`, `.opencode/commands/errors.md`, `.opencode/commands/refresh.md`, `.opencode/docs/guides/creating-commands.md`

---

### 520. Remove OC_ prefix from OpenCode documentation and standards
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-05-04T14:00:00Z
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [520_remove_oc_prefix_opencode_documentation/reports/01_oc-prefix-audit.md]
- **Plan**: [520_remove_oc_prefix_opencode_documentation/plans/01_oc-prefix-removal-plan.md]
- **Summary**: [520_remove_oc_prefix_opencode_documentation/summaries/01_oc-prefix-removal-summary.md]

**Description**: Audit and update all `.opencode/` files that reference `OC_` prefix to use plain task numbers. The actual task directories already use plain numbers (`specs/517_slug/`), and `state.json`/`TODO.md` store plain integers. However, documentation throughout `.opencode/` still instructs agents to use `OC_` prefix (`specs/OC_517_slug/`, `task OC_17`, etc.), creating confusion. Update context standards, patterns, skills, docs, and rules. Key affected areas: `.opencode/context/core/standards/task-management.md`, `.opencode/context/core/orchestration/state-management.md`, `.opencode/context/core/patterns/*.md`, `.opencode/skills/skill-todo/SKILL.md`, `.opencode/skills/skill-memory/SKILL.md`, `.opencode/docs/guides/phase-synchronization.md`, `.opencode/rules/artifact-formats.md`. Rename legacy `OC_503_*` directory if needed.

Key files: `.opencode/context/core/standards/task-management.md`, `.opencode/context/core/orchestration/state-management.md`, `.opencode/context/core/patterns/*.md`, `.opencode/skills/skill-todo/SKILL.md`, `.opencode/skills/skill-memory/SKILL.md`, `.opencode/docs/guides/phase-synchronization.md`, `.opencode/rules/artifact-formats.md`

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
- **Research Started**: 2026-02-13
- **Research Completed**: 2026-02-13
- **Planning Started**: 2026-02-13
- **Planning Completed**: 2026-02-13
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [078_fix_himalaya_smtp_authentication_failure/reports/research-001.md]
- **Plan**: [078_fix_himalaya_smtp_authentication_failure/plans/implementation-001.md]

**Description**: Fix Gmail SMTP authentication failure when sending emails via Himalaya (<leader>me). Error: "Authentication failed: Code: 535, Enhanced code: 5.7.8, Message: Username and Password not accepted". The error occurs with TLS connection attempts and persists through multiple retry attempts. Identify and fix the root cause of the SMTP credential configuration.

## Recommended Order

1. **516** -> research (independent)
2. **517** -> research (independent)
