---
next_project_number: 557
---

# TODO

## Task Order

*Updated 2026-05-08. 6 active tasks remaining.*

### Pending
- **556** [IMPLEMENTING] -- Add literature awareness to planner, research agents, and lean4 rule (depends: 553)
- **555** [COMPLETED] -- Update proof workflow docs with literature-first stages (depends: 553)
- **554** [COMPLETED] -- Create literature fidelity policy for Formal extension
- **553** [COMPLETED] -- Create literature fidelity policy for Lean extension
- **551** [COMPLETED] -- Fix discord-link.lua session discovery to match actual opencode session list output
- **550** [COMPLETED] -- Unify Ctrl-CR toggle for OpenCode and ClaudeCode and add leader-ac agent picker
- **549** [COMPLETED] -- Audit and relocate external /tmp/ references to specs/tmp/ (depends: 548)
- **547** [COMPLETED] -- Research mobile agent management via Discord bot on NixOS
- **500** [RESEARCHED] -- Add context: fork frontmatter to core delegating skills (depends: 499)
- **501** [PLANNED] -- Optimize team-mode skills for FORK_SUBAGENT parallel cache sharing (depends: 499)
- **87** [RESEARCHED] -- Investigate terminal directory change in wezterm
- **78** [PLANNED] -- Fix Himalaya SMTP authentication failure

## Tasks

### 556. Add literature awareness to planner, research agents, and lean4 rule
- **Effort**: 1-2 hours
- **Status**: [IMPLEMENTING]
- **Task Type**: meta
- **Dependencies**: Task #553
- **Research**: [556_literature_awareness_planner_research/reports/01_literature-awareness-agents.md]
- **Plan**: [556_literature_awareness_planner_research/plans/01_literature-awareness-agents.md]

**Description**: Add literature-following guidance to three agent/rule files and update the context index. (1) `planner-agent.md`: For formal/lean tasks with literature references, structure plan phases to mirror the literature's proof steps rather than inventing a novel decomposition. (2) `lean-research-agent.md`: During research, extract and document the proof structure from provided literature so downstream agents have a step-by-step map. (3) `lean4.md` auto-applied rule: Add a "Literature Fidelity" section that fires on every `*.lean` file edit, reminding agents to follow provided literature when available. (4) Update `lean/index-entries.json` to load the literature fidelity policy (task 553) for lean-implementation-agent.

Key files: `.claude/agents/planner-agent.md`, `.claude/extensions/lean/agents/lean-research-agent.md`, `.claude/extensions/lean/rules/lean4.md`, `.claude/extensions/lean/index-entries.json`

---

### 555. Update proof workflow docs with literature-first stages
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #553
- **Research**: [555_update_proof_workflow_literature/reports/01_proof-workflow-literature.md]
- **Plan**: [555_update_proof_workflow_literature/plans/01_proof-workflow-literature.md]
- **Summary**: [555_update_proof_workflow_literature/summaries/01_proof-workflow-literature-summary.md]
- **Completed**: 2026-05-12
- **Summary**: Added literature-first stages to 3 proof workflow documents: Stage 1.5 and modified Stage 4B/Tactic Selection in lean-implementation-flow.md, Step 0 and modified Step 2/dependencies/criteria in end-to-end-proof-workflow.md, and literature-guided strategy/sketch/references in proof-construction.md. All changes are mode-gated.

**Description**: Modify three proof workflow documents to integrate literature-first stages before tactic exploration and automation. (1) `lean-implementation-flow.md`: Add "Stage 1.5: Check for Literature Source" between parsing delegation context and loading plan -- if a literature source is referenced, load it and identify the proof strategy before entering the proof development loop. Modify Stage 4B proof loop to consult literature FIRST before trying `lean_multi_attempt` or automation. (2) `end-to-end-proof-workflow.md`: Add "Step 0: Check for Literature Source" prerequisite; modify Step 2 (Outline the Proof) to follow the literature's structure when provided. (3) `proof-construction.md` (formal extension): Add literature-first strategy to the "Choose Strategy" section -- when a reference proof exists, the strategy is "follow the reference" not "choose between direct/indirect/induction."

Key files: `.claude/extensions/lean/context/project/lean4/agents/lean-implementation-flow.md`, `.claude/extensions/lean/context/project/lean4/processes/end-to-end-proof-workflow.md`, `.claude/extensions/formal/context/project/logic/processes/proof-construction.md`

---

### 554. Create literature fidelity policy for Formal extension
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Research**: [554_literature_fidelity_formal_policy/reports/01_literature-fidelity-formal.md]
- **Plan**: [554_literature_fidelity_formal_policy/plans/01_literature-fidelity-formal.md]
- **Summary**: [554_literature_fidelity_formal_policy/summaries/01_literature-fidelity-formal-summary.md]
- **Completed**: 2026-05-12
- **Summary**: Created literature-fidelity-policy.md (257 lines) for the formal extension defining two agent modes (literature-guided and first-principles), 5 FORBIDDEN anti-patterns, 5-level escalation protocol, domain-specific guidance for logic/math/physics, and success criteria checklist. Registered in index-entries.json for all 4 research agents plus general-implementation-agent with languages filter.

**Description**: Create a literature fidelity policy document for the formal extension at `.claude/extensions/formal/context/project/logic/standards/literature-fidelity-policy.md`, matching the pattern established in task 553 for the Lean extension. Covers logic, math, and physics domains. The policy defines: (1) When a literature source is provided (paper, textbook, notes), follow its proof/argument structure step-by-step. (2) When no literature is provided, derive from first principles. (3) Escalation protocol: when a literature step doesn't translate cleanly, document the gap and ask rather than improvising. (4) Anti-patterns: seeking shortcuts when the literature proof is hard, attempting novel approaches that bypass difficult steps, using automation to skip parts the literature handles explicitly. Update `formal/index-entries.json` to load this policy for formal research and implementation agents.

Key files: `.claude/extensions/formal/context/project/logic/standards/literature-fidelity-policy.md`, `.claude/extensions/formal/index-entries.json`

---

### 553. Create literature fidelity policy for Lean extension
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Research**: [553_literature_fidelity_lean_policy/reports/01_literature-fidelity-lean.md]
- **Plan**: [553_literature_fidelity_lean_policy/plans/01_literature-fidelity-lean.md]
- **Summary**: [553_literature_fidelity_lean_policy/summaries/01_literature-fidelity-lean-summary.md]
- **Completed**: 2026-05-12
- **Summary**: Created literature-fidelity-policy.md (126 lines) defining two agent modes (literature-guided and first-principles), 4 FORBIDDEN anti-patterns, 6-step escalation protocol, and usage checklist. Registered in index-entries.json for lean-implementation-agent and lean-research-agent.

**Description**: Create a standalone literature fidelity policy document at `.claude/extensions/lean/context/project/lean4/standards/literature-fidelity-policy.md`. This is the core policy that all other literature-awareness tasks reference. The policy defines two modes: (1) **Literature-guided mode** (activated when a literature source is provided in the task description, plan, or research artifacts): Follow the source's proof structure step-by-step; do not seek shortcuts even when the proof is hard; translate each literature step into Lean tactics/terms faithfully; when a step doesn't translate, document the gap and escalate rather than improvising. (2) **First-principles mode** (default when no literature is provided): Current behavior -- use tactic exploration, MCP search, automation freely. The policy includes an anti-pattern catalog: (a) "The proof is hard so I'll try simp/omega/aesop instead" (b) "I'll find an easier approach" when the literature's approach is the standard one (c) Abandoning the literature's strategy after a single failed tactic attempt (d) Mixing literature steps with novel steps without flagging the deviation. Also includes an escalation protocol: when stuck on a literature step, re-read the source, try alternative Lean encodings of the same mathematical step, and only after exhausting faithful translations flag the gap to the user.

Key files: `.claude/extensions/lean/context/project/lean4/standards/literature-fidelity-policy.md`

---

### 551. Fix discord-link.lua session discovery to match actual opencode session list output
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Research**: [551_fix_discord_link_session_discovery/reports/01_fix-session-discovery.md]
- **Plan**: [551_fix_discord_link_session_discovery/plans/01_fix-session-discovery.md]
- **Summary**: [551_fix_discord_link_session_discovery/summaries/01_fix-session-discovery-summary.md]
- **Completed**: 2026-05-09
- **Summary**: Fixed discord-link.lua session discovery to use correct opencode CLI field names (directory, id, title) instead of nonexistent fields (working_directory, cwd, status, session_id, name). Replaced broken status-based fallback with most-recent-session fallback. Updated discord-session-picker.lua to prioritize correct field names while keeping bot API names as fallbacks.

**Description**: Fix discord-link.lua session discovery to match actual opencode session list --format json output. The command returns sessions with field `directory` (not `working_directory` or `cwd`) and no `status` field. Current code at discord-link.lua:198 checks `sess.working_directory == cwd` or `sess.cwd == cwd` which never matches. The fallback at line 206 checks `sess.status == "active"` or `sess.status == "running"` which also never matches since there is no status field. Fix: (1) change the CWD filter to check `sess.directory == cwd`, (2) remove the status-based fallback and instead use the first session matching the CWD, or if none match, use the most recent session (first in the list since they're sorted by updated descending), (3) use `sess.id` for session_id and `sess.title` for session_name (both exist in the actual output). Also check discord-session-picker.lua for the same field name mismatches.

### 550. Unify Ctrl-CR toggle for OpenCode and ClaudeCode and add leader-ac agent picker
- **Effort**: 2-4 hours
- **Status**: [COMPLETED]
- **Task Type**: neovim
- **Research**: [550_unify_ctrl_cr_toggle_and_agent_picker/reports/01_ctrl-cr-agent-picker.md]
- **Plan**: [550_unify_ctrl_cr_toggle_and_agent_picker/plans/01_ctrl-cr-agent-picker.md]
- **Summary**: [550_unify_ctrl_cr_toggle_and_agent_picker/summaries/01_ctrl-cr-agent-picker-summary.md]
- **Completed**: 2026-05-08
- **Summary**: Fixed <C-CR> toggle for ClaudeCode by replacing heuristic buffer detection with claude-code.nvim's instance registry query and adding centralized _active_tool state tracking with TermClose/BufWipeout cleanup autocmds. Added <leader>ac keymap for direct agent picker access via which-key.

**Description**: Fix Ctrl-CR (`<C-CR>`) toggle behavior so it works uniformly for both OpenCode and ClaudeCode. Currently, after launching OpenCode via the `<C-CR>` picker, `<C-CR>` toggles the OpenCode sidebar as expected. However, after launching ClaudeCode the same way, `<C-CR>` does nothing. Both should toggle consistently. Additionally, add a `<leader>ac` keymap to launch the agent picker (the same picker shown initially by `<C-CR>`) so that when either OpenCode or ClaudeCode is already running, the user can switch to the other agent or select a past session. This feature should integrate naturally with the existing AI tool infrastructure.

### 549. Audit and relocate external /tmp/ references to specs/tmp/ (depends: 548)
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: Task #548
- **Research**: [549_audit_relocate_temp_files/reports/01_relocate-tmp-files.md]
- **Plan**: [549_audit_relocate_temp_files/plans/01_relocate-tmp-files.md]
- **Summary**: [549_audit_relocate_temp_files/summaries/01_relocate-tmp-files-summary.md]

**Description**: Replace all `/tmp/` file path references in OpenCode agent/skill definitions with `specs/tmp/` paths to keep temporary files within the project root. Eight files need updating: `skill-nix-implementation/SKILL.md` (5 refs), `skill-neovim-implementation/SKILL.md` (3 refs), `skill-lean-implementation/SKILL.md` (3 refs), `skill-lean-research/SKILL.md` (3 refs), `spreadsheet-agent.md` (1 ref). Also verify `specs/tmp/` exists and document the temp file location convention. Goal: eliminate all permission prompts caused by OpenCode agents writing to `/tmp/` outside the project root.

Key files: `.opencode/skills/skill-nix-implementation/SKILL.md`, `.opencode/skills/skill-neovim-implementation/SKILL.md`, `.opencode/skills/skill-lean-implementation/SKILL.md`, `.opencode/skills/skill-lean-research/SKILL.md`, `.opencode/agent/subagents/spreadsheet-agent.md`

---

### 547. Research mobile agent management via Discord bot on NixOS
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Summary**: Implemented Neovim-side Discord integration with session linking command (:OpenCodeLinkDiscord / <leader>ar) and Telescope session picker (:DiscordSessions / <leader>aD). Both modules communicate with the Discord bot HTTP API using async curl requests.
- **Task Type**: meta
- **Dependencies**: None
- **Research**:
  - [547_research_mobile_agent_management/reports/01_mobile-agent-management-research.md]
  - [547_research_mobile_agent_management/reports/02_team-research.md]
- **Plan**:
  - [547_research_mobile_agent_management/plans/01_discord-bot-neovim-setup.md]
  - [547_research_mobile_agent_management/plans/02_discord-bot-revised.md]
- **Summary Artifact**: [547_research_mobile_agent_management/summaries/02_discord-neovim-summary.md]

**Description**: Research and design a mobile agent management system allowing OpenCode agent sessions to be managed from an iPhone. Scope: (1) Discord bot library selection in 2026 (discord.py vs alternatives), slash command design, and NixOS hosting. (2) OpenCode headless/daemon mode investigation for programmatic agent session management. (3) Mosh installation and iPhone client setup on NixOS as fallback terminal access. (4) Raspberry Pi agent runtime configuration (lightweight NixOS or containerized). (5) Security considerations for remote agent access (token management, SSH hardening, permission scoping). (6) Architecture design for the Discord bot as an OpenCode agent management layer. Deliverable: research report with concrete recommendations and a phased implementation roadmap.

Key files: `.opencode/`, NixOS configuration, Discord bot scaffolding

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
| 1 | 549 | [RESEARCHED] | /plan 549 |
| 2 | 547 | [PLANNED] | /implement 547 |
| 3 | 500 | [RESEARCHED] | /plan 500 |
| 4 | 501 | [PLANNED] | /implement 501 |
| 5 | 87 | [RESEARCHED] | /plan 87 |
| 6 | 78 | [PLANNED] | /implement 78 |

---

## Recently Completed

| Task | Name | Completed |
|------|------|-----------|
| 548 | Research OpenCode permission system for workspace-root auto-approval | 2026-05-07 |
| 546 | Audit and align other multi-task creators for consistent insertion | 2026-05-08 |
| 545 | Harden TODO.md insertion ordering in meta-builder-agent | 2026-05-08 |
| 544 | Fix OpenCode session picker restore/browse options | 2026-05-07 |
| 543 | Convert opencode.json to fully computed artifact (like CLAUDE.md) | 2026-05-07 |
| 542 | Implement opencode.json automatic agent registration in extension loader | 2026-05-08 |
| 541 | Design opencode.json agent registration for extensions | 2026-05-07 |
| 540 | Research opencode.json and extension agent registration gaps | 2026-05-07 |
| 539 | Uniform extension routing: one source of truth, zero hardcoding | 2026-05-07 |
| 538 | Add automated routing table validation | 2026-05-07 |
| 537 | Fix manifest discovery to use absolute paths | 2026-05-07 |
| 536 | Clarify two-step delegation chain in command docs | 2026-05-07 |
| 535 | Establish single source of truth for resume points | 2026-05-07 |
| 534 | Sync extension routing tables across command docs | 2026-05-07 |
| 533 | Fix extension loader to copy manifest.json | 2026-05-07 |
| 528 | Update skill-implementer continuation loop and pattern documentation | 2026-05-05 |
| 527 | Update handoff artifact naming convention in format specs and agent definitions | 2026-05-05 |

## Recommended Order


## Recommended Order


## Recommended Order

