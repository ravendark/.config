---
next_project_number: 540
---

# TODO

## Task Order

*Updated 2026-05-07. 16 active tasks remaining.*

### Pending
- **534** [COMPLETED] -- Sync extension routing tables across command docs
- **535** [COMPLETED] -- Establish single source of truth for resume points
- **536** [COMPLETED] -- Clarify two-step delegation chain in command docs
- **537** [COMPLETED] -- Fix manifest discovery to use absolute paths
- **538** [COMPLETED] -- Add automated routing table validation
- **533** [COMPLETED] -- Fix extension loader to copy manifest.json

### Pending
- **539** [RESEARCHED] -- Uniform extension routing: one source of truth, zero hardcoding (depends: 538)
- **528** [COMPLETED] -- Update skill-implementer continuation loop and pattern documentation (depends: 527)
- **527** [COMPLETED] -- Update handoff artifact naming convention in format specs and agent definitions
- **500** [RESEARCHED] -- Add context: fork frontmatter to core delegating skills (depends: 499)
- **501** [PLANNED] -- Optimize team-mode skills for FORK_SUBAGENT parallel cache sharing (depends: 499)
- **87** [RESEARCHED] -- Investigate terminal directory change in wezterm
- **78** [PLANNED] -- Fix Himalaya SMTP authentication failure

## Tasks

### 539. Uniform extension routing: one source of truth, zero hardcoding
- **Effort**: 3-4 hours
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: Task #538
- **Research**: [539_uniform_extension_routing/reports/01_uniform-routing-research.md]
- **Plan**: [539_uniform_extension_routing/README.md]

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

## Recommended Order
