---
next_project_number: 550
---

# TODO

## Task Order

*Updated 2026-05-07. 19 active tasks remaining.*

### Pending
- **548** [RESEARCHED] -- Research OpenCode permission system for workspace-root auto-approval
- **549** [NOT STARTED] -- Audit and relocate external /tmp/ references to specs/tmp/ (depends: 548)
- **545** [COMPLETED] -- Harden TODO.md insertion ordering in meta-builder-agent
- **546** [NOT STARTED] -- Audit and align other multi-task creators for consistent insertion (depends: 545)
- **534** [COMPLETED] -- Sync extension routing tables across command docs
- **535** [COMPLETED] -- Establish single source of truth for resume points
- **536** [COMPLETED] -- Clarify two-step delegation chain in command docs
- **537** [COMPLETED] -- Fix manifest discovery to use absolute paths
- **538** [COMPLETED] -- Add automated routing table validation
- **533** [COMPLETED] -- Fix extension loader to copy manifest.json

### Pending
- **544** [COMPLETED] -- Fix OpenCode session picker restore/browse options
- **540** [COMPLETED] -- Research opencode.json and extension agent registration gaps
- **541** [COMPLETED] -- Design opencode.json agent registration for extensions (depends: 540)
- **542** [COMPLETED] -- Implement opencode.json automatic agent registration in extension loader (depends: 541)
- **543** [RESEARCHED] -- Convert opencode.json to fully computed artifact (like CLAUDE.md) (depends: 542)
- **539** [COMPLETED] -- Uniform extension routing: one source of truth, zero hardcoding (depends: 538)
- **528** [COMPLETED] -- Update skill-implementer continuation loop and pattern documentation (depends: 527)
- **527** [COMPLETED] -- Update handoff artifact naming convention in format specs and agent definitions
- **500** [RESEARCHED] -- Add context: fork frontmatter to core delegating skills (depends: 499)
- **501** [PLANNED] -- Optimize team-mode skills for FORK_SUBAGENT parallel cache sharing (depends: 499)
- **87** [RESEARCHED] -- Investigate terminal directory change in wezterm
- **78** [PLANNED] -- Fix Himalaya SMTP authentication failure

## Tasks

### 548. Research OpenCode permission system for workspace-root auto-approval
- **Effort**: 1-2 hours
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [548_research_opencode_permissions/reports/01_opencode-permissions-research.md]

**Description**: Research how OpenCode's permission system works and how to configure it to always grant permission for file changes within the current project root directory while still requiring approval for writes outside the root. Investigate: (1) OpenCode permission configuration files (opencode.json or equivalent), (2) available permission scoping options (directory-based, tool-based), (3) security implications of auto-approving workspace-root writes, (4) best practices from OpenCode documentation and community. Deliverable: research report with concrete configuration recommendations.

Key files: `opencode.json` (if it exists), OpenCode CLI documentation, `.opencode/` configuration

---

### 549. Audit and relocate external /tmp/ references to specs/tmp/ (depends: 548)
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: Task #548

**Description**: Replace all `/tmp/` file path references in OpenCode agent/skill definitions with `specs/tmp/` paths to keep temporary files within the project root. Eight files need updating: `skill-nix-implementation/SKILL.md` (5 refs), `skill-neovim-implementation/SKILL.md` (3 refs), `skill-lean-implementation/SKILL.md` (3 refs), `skill-lean-research/SKILL.md` (3 refs), `spreadsheet-agent.md` (1 ref). Also verify `specs/tmp/` exists and document the temp file location convention. Goal: eliminate all permission prompts caused by OpenCode agents writing to `/tmp/` outside the project root.

Key files: `.opencode/skills/skill-nix-implementation/SKILL.md`, `.opencode/skills/skill-neovim-implementation/SKILL.md`, `.opencode/skills/skill-lean-implementation/SKILL.md`, `.opencode/skills/skill-lean-research/SKILL.md`, `.opencode/agent/subagents/spreadsheet-agent.md`

---

### 547. Research mobile agent management via Discord bot on NixOS
- **Effort**: 2-3 hours
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [547_research_mobile_agent_management/reports/01_mobile-agent-management-research.md]

**Description**: Research and design a mobile agent management system allowing OpenCode agent sessions to be managed from an iPhone. Scope: (1) Discord bot library selection in 2026 (discord.py vs alternatives), slash command design, and NixOS hosting. (2) OpenCode headless/daemon mode investigation for programmatic agent session management. (3) Mosh installation and iPhone client setup on NixOS as fallback terminal access. (4) Raspberry Pi agent runtime configuration (lightweight NixOS or containerized). (5) Security considerations for remote agent access (token management, SSH hardening, permission scoping). (6) Architecture design for the Discord bot as an OpenCode agent management layer. Deliverable: research report with concrete recommendations and a phased implementation roadmap.

Key files: `.opencode/`, NixOS configuration, Discord bot scaffolding

---

### 545. Harden TODO.md insertion ordering in meta-builder-agent
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [545_harden_todo_md_insertion/reports/01_todo-insertion-research.md]
- **Plan**: [545_harden_todo_md_insertion/plans/01_todo-insertion-plan.md]
- **Summary**: [545_harden_todo_md_insertion/summaries/01_todo-insertion-summary.md]

**Description**: Update `meta-builder-agent.md` Stage 6 (CreateTasks + Status Updates) to replace the abstract `insert_after_heading("## Tasks", batch_markdown)` pseudocode with an explicit, LLM-proof Edit tool invocation. The current pseudocode allows LLM agents to append tasks at the bottom of TODO.md instead of prepending them at the top (as seen with task 544). Changes: (1) Replace pseudocode with concrete `oldString:"## Tasks\n"` → `newString:"## Tasks\n\n{batch}\n"` Edit call. (2) Add post-insertion verification: re-read first task after `## Tasks` and confirm it matches the foundational task number. (3) Add bold warning against searching for last `---` separator or appending. (4) Sync changes to `.opencode/extensions/core/agents/meta-builder-agent.md`.

Key files: `.opencode/agent/subagents/meta-builder-agent.md`, `.opencode/extensions/core/agents/meta-builder-agent.md`

---

### 546. Audit and align other multi-task creators for consistent insertion
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: Task #545

**Description**: Apply the hardened insertion pattern from task 545 to all other multi-task creators in the system. Audit skill-fix-it (`SKILL.md` line ~466: "Prepend new task entry to `## Tasks` section"), /review, /errors, and `/task --review` to: (1) Replace any abstract pseudocode with the same concrete Edit tool pattern. (2) Update `multi-task-creation-standard.md` component 8 (State Updates) with the hardened pattern. (3) Ensure all creators pass through the same insertion logic for consistent, predictable TODO.md ordering.

Key files: Skill definitions (skill-fix-it, skill-test, etc.), `multi-task-creation-standard.md`

---

### 540. Research opencode.json and extension agent registration gaps
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [540_research_opencode_json_and_extension_gaps/reports/01_opencode-json-research.md]
- **Plan**: [540_research_opencode_json_and_extension_gaps/plans/01_opencode-json-plan.md]
- **Summary**: [540_research_opencode_json_and_extension_gaps/summaries/01_opencode-json-summary.md]

**Description**: Research the opencode.json configuration file schema and how the OpenCode CLI consumes it at startup. Document the current gap where extensions copy agent files to `.opencode/agent/subagents/` but do NOT register them in `opencode.json`, leaving the CLI unaware of extension-provided agents. Investigate the recent crash scenario where `opencode --port` failed with config validation errors due to missing agent files referenced in `opencode.json`. Analyze the `merge_opencode_agents()` and `unmerge_opencode_agents()` functions in `merge.lua` that already exist but are unused by all extension manifests. Determine the correct opencode.json fragment format for each extension's agents and whether the base template at `.opencode/templates/opencode.json` needs updates.

Key files: `opencode.json` (project root), `.opencode/templates/opencode.json`, `merge.lua` (`merge_opencode_agents`/`unmerge_opencode_agents`), extension manifests (`latex`, `python`, `nvim`, `lean`, `nix`, `typst`, etc.)

---

### 541. Design opencode.json agent registration for extensions
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #540
- **Research**: [541_design_opencode_json_agent_registration/reports/01_opencode-json-agent-registration-design.md]
- **Plan**: [541_design_opencode_json_agent_registration/plans/01_opencode-json-agent-registration-plan.md]
- **Summary**: [541_design_opencode_json_agent_registration/summaries/01_opencode-json-agent-registration-summary.md]

**Description**: Design the complete opencode.json agent registration mechanism for the extension system. For each extension that provides agents, create an `opencode.json` fragment file containing the agent definitions with proper `mode`, `description`, `prompt` (using `{file:...}` placeholders), and `tools` configuration. Update all extension manifests to include `merge_targets.opencode_json` pointing to these fragments. Design the merge/unmerge strategy: when an extension is loaded, its agents are added to the project's `opencode.json` without overwriting existing agents; when unloaded, only the agents added by that extension are removed. Design validation: before writing `opencode.json`, verify all `{file:...}` references point to files that actually exist on disk to prevent startup crashes.

Key files: Extension manifests (add `merge_targets.opencode_json`), new fragment files (`extensions/*/opencode-agents.json`), `.opencode/templates/opencode.json`

---

### 542. Implement opencode.json automatic agent registration in extension loader
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Dependencies**: Task #541
- **Research**: [542_implement_opencode_json_agent_registration/reports/01_opencode-json-agent-registration-research.md]
- **Plan**: [542_implement_opencode_json_agent_registration/plans/01_opencode-json-agent-registration-plan.md]
- **Summary**: [542_implement_opencode_json_agent_registration/summaries/01_opencode-json-agent-registration-summary.md]

**Description**: Implement the designed opencode.json agent registration in the Neovim extension loader. Create `opencode-agents.json` fragment files for all extensions that provide agents (latex, python, nvim, lean, nix, typst, web, founder, present, filetypes, etc.). Update each extension's `manifest.json` with `merge_targets.opencode_json` pointing to the fragment. Update the base `opencode.json` template to include documentation about the managed-file marker (`.opencode.json.managed`). Enhance `merge_opencode_agents()` to validate that all `{file:...}` references in the merged result exist before writing. Add a verification step in `verify.lua` to check that all agents in `opencode.json` have corresponding files on disk. Test load/unload cycles for extensions with agents to ensure proper registration and cleanup.

Key files: `lua/neotex/plugins/ai/shared/extensions/merge.lua`, `lua/neotex/plugins/ai/shared/extensions/verify.lua`, extension manifests, new fragment files, `.opencode/templates/opencode.json`

---

### 543. Convert opencode.json to fully computed artifact (like CLAUDE.md)
- **Effort**: 2-3 hours
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: Task #542
- **Research**: [543_convert_opencode_json_to_computed_artifact/reports/01_computed-artifact-pattern.md]

**Description**: Replace the merge-target approach for `opencode.json` with a computed-artifact pattern, analogous to how `generate_claudemd()` in `merge.lua` rebuilds `CLAUDE.md` from scratch after every load/unload cycle. Research the `generate_claudemd()` pattern, design a `generate_opencode_json()` function that aggregates agent entries from all loaded extensions, and implement the regeneration pipeline. Document the computed-artifact pattern in `.opencode/context/patterns/computed-artifacts.md` for future use with other merge-target files.

Key files: `lua/neotex/plugins/ai/shared/extensions/merge.lua`, `opencode.json`, `.opencode/context/patterns/computed-artifacts.md`

---

### 539. Uniform extension routing: one source of truth, zero hardcoding
- **Effort**: 3-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #538
- **Research**: [539_uniform_extension_routing/reports/01_uniform-routing-research.md]
- **Plan**:
  - [539_uniform_extension_routing/README.md]
  - [539_uniform_extension_routing/plans/01_uniform-routing-plan.md]
- **Summary**: [539_uniform_extension_routing/summaries/01_uniform-routing-summary.md]

**Description**: Audit all extension manifests and command docs to eliminate hardcoded routing tables and establish `manifest.json` as the single source of truth. Add missing `routing` sections to 8 extensions (latex, formal, filetypes, epidemiology, nix, z3, web, python) that have skills but no routing. Remove hardcoded "Extension-Based Routing Table" sections from `/implement`, `/research`, `/plan` command docs. Update Anti-Bypass constraints to reference manifest discovery instead of listing skills by name. Update the validation script to check manifests directly rather than comparing against command doc tables. Goal: manifest discovery alone determines routing with zero silent fallbacks.

Key files: `.opencode/extensions/*/manifest.json`, `.opencode/commands/{implement,research,plan}.md`, `.opencode/scripts/validate-routing-tables.sh`

---

### 533. Fix extension loader to copy manifest.json
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Dependencies**: None
- **Research**:
  - [533_fix_extension_loader_manifest/reports/01_extension-loader-manifest-research.md]
- **Plan**:
  - [533_fix_extension_loader_manifest/README.md]
  - [533_fix_extension_loader_manifest/plans/01_fix-extension-loader-manifest.md]
- **Summary**: [533_fix_extension_loader_manifest/summaries/01_fix-extension-loader-manifest-summary.md]

**Description**: Fix the Neovim extension loader to copy `manifest.json` into target projects during `manager.load()`. The extension loader currently copies all extension files except `manifest.json`, which breaks agent routing in `/implement`, `/research`, and `/plan` commands. These commands scan `.opencode/extensions/*/manifest.json` to determine task-type-to-skill mappings. Without the manifest, specialized tasks (e.g., `type:lean4`) silently fall back to generic agents. This task also updates `manager.unload()` to remove the manifest and `verify.lua` to confirm its presence.

Key files: Neovim extension loader Lua source, `verify.lua`

---

### 538. Add automated routing table validation
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #534
- **Plan**: [538_automated_routing_validation/README.md]

**Description**: Create `.opencode/scripts/validate-routing-tables.sh` that parses extension manifests and validates command docs include all task types. Integrate into pre-commit or CI to prevent future routing table drift. Depends on Task 534 (tables must be synced first).

Key files: `.opencode/scripts/validate-routing-tables.sh`

---

### 537. Fix manifest discovery to use absolute paths
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Plan**: [537_fix_manifest_absolute_paths/README.md]

**Description**: Update `/implement`, `/research`, and `/plan` commands to derive absolute paths for manifest discovery from the project root. Add working-directory verification and explicit errors when manifests cannot be found. Prevents silent fallback when agent CWD differs from project root.

Key files: `.opencode/commands/implement.md`, `.opencode/commands/research.md`, `.opencode/commands/plan.md`

---

### 536. Clarify two-step delegation chain in command docs
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Plan**: [536_clarify_delegation_chain/README.md]

**Description**: Update DELEGATE sections in `/implement`, `/research`, and `/plan` to explicitly document the two-step delegation chain: (1) `Skill` tool loads skill instructions, (2) follow loaded instructions to invoke `Task` tool with subagent. Add warning: "DO NOT use `Skill(agent-name)`".

Key files: `.opencode/commands/implement.md`, `.opencode/commands/research.md`, `.opencode/commands/plan.md`

---

### 535. Establish single source of truth for resume points
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Plan**: [535_establish_resume_point_truth/README.md]

**Description**: Update `/implement` command and implementation skills to use plan file phase markers as the PRIMARY source of truth for resume points. `state.json` `resume_phase` becomes secondary. When sources disagree, prefer plan markers and log a warning.

Key files: `.opencode/commands/implement.md`, `.opencode/skills/skill-implementer/SKILL.md`

---

### 534. Sync extension routing tables across command docs
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Plan**: [534_sync_extension_routing_tables/README.md]

**Description**: Update `/implement`, `/research`, and `/plan` command docs to include ALL extension languages (`lean`, `lean4`, `nix`, `neovim`, `typst`, `latex`) in their Extension-Based Routing Tables. Update Anti-Bypass Constraint to reference all applicable skills.

Key files: `.opencode/commands/implement.md`, `.opencode/commands/research.md`, `.opencode/commands/plan.md`

---

### 528. Update skill-implementer continuation loop and pattern documentation
- **Effort**: < 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #527
- **Research**:
  - [528_update_continuation_loop_docs/reports/01_continuation-loop-docs-research.md]
- **Plan**: [528_update_continuation_loop_docs/plans/01_update-continuation-loop-docs.md]
- **Summary**: [528_update_continuation_loop_docs/summaries/01_update-continuation-loop-docs-summary.md]

**Description**: Update `skill-implementer/SKILL.md` example paths in the continuation loop documentation and Stage 7 partial handling to use the new `MM_HH_{handoff-slug}.md` naming convention. Update `subagent-continuation-loop.md` and `context-exhaustion-detection.md` pattern documents with new example `handoff_path` values. Sync all changes to `.opencode/extensions/core/` mirrors.

Key files: `.opencode/skills/skill-implementer/SKILL.md`, `.opencode/context/patterns/subagent-continuation-loop.md`, `.opencode/context/patterns/context-exhaustion-detection.md`

---

### 527. Update handoff artifact naming convention in format specs and agent definitions
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**:
  - [527_update_handoff_naming_convention/reports/01_handoff-naming-research.md]
- **Plan**: [527_update_handoff_naming_convention/plans/01_update-handoff-naming.md]
- **Summary**: [527_update_handoff_naming_convention/summaries/01_update-handoff-naming-summary.md]

**Description**: Update the handoff artifact system to use the `MM_HH_{handoff-slug}.md` naming convention where MM is the plan artifact number and HH is the handoff artifact number. Update `handoff-artifact.md` format spec with the new naming convention and slug generation guidelines (derive from phase name + current objective, kebab-case). Update `general-implementation-agent.md` Stage 4C to construct filenames using `artifact_number` (MM), `handoff_count+1` (HH, zero-padded to 2 digits), and auto-generated slug. Update extension/core/ mirrors and `lean-implementation-agent.md` references.

Key files: `.opencode/context/formats/handoff-artifact.md`, `.opencode/agent/subagents/general-implementation-agent.md`, `.opencode/extensions/lean/agents/lean-implementation-agent.md`

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

**Description**: Optimize skill-team-research, skill-team-plan, and skill-team-implement to maximize CLAUDE_CODE_FORK_SUBAGENT parallel cache sharing benefits. With FORK_SUBAGENT=1, teammates 2-N sharing the parent's cached prefix get ~90% input token cost reduction. Investigate: (1) Whether teammate spawning currently inherits the prompt cache or starts fresh. (2) If restructuring teammate dispatch order or context preparation can improve cache hit rates. (3) Whether the default team_size=2 should be reconsidered given reduced costs per additional teammate. (4) Update team orchestration patterns and metadata to track cache savings. Files: `.claude/skills/skill-team-research/SKILL.md`, `.claude/skills/skill-team-plan/SKILL.md`, `.claude/skills/skill-team-implement/SKILL.md`, `.claude/context/patterns/team-orchestration.md`.

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

### 544. Fix OpenCode session picker restore/browse options
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [544_fix_opencode_session_picker/reports/01_session-picker-timing.md]
- **Plan**: [544_fix_opencode_session_picker/plans/01_session-picker-timing-fix.md]
- **Summary**: [544_fix_opencode_session_picker/summaries/01_session-picker-timing-fix-summary.md]

**Description**: Fix the "Restore last session" and "Browse all sessions" options in the OpenCode session picker (`<C-CR>` → OpenCode). Currently, these options use `vim.defer_fn(..., 1000)` to wait for the OpenCode server, which is unreliable. Replace with proper server-ready detection that polls or waits for the `OpencodeEvent:server.connected` event before making session API calls (`server:select_session()`, `select_session()`). The "Create new session" option already works (it just opens a terminal). Ensure all three options work reliably with proper error handling for edge cases (server startup failure, no saved sessions, etc.).

Key files: `lua/neotex/plugins/ai/ai-tool-picker.lua`, opencode.nvim plugin session API

---

## Recommended Order
