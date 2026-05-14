---
next_project_number: 573
---

# TODO

## Task Order

*Updated 2026-05-13. 7 active tasks remaining.*

### Pending
- **568** [COMPLETED] -- Update artifact formats for deviation tracking
- **569** [COMPLETED] -- Enhance general implementation agent (depends: 568)
- **570** [COMPLETED] -- Propagate improvements to extension agents (depends: 569)
- **500** [RESEARCHED] -- Add context: fork frontmatter to core delegating skills (depends: 499)
- **501** [PLANNED] -- Optimize team-mode skills for FORK_SUBAGENT parallel cache sharing (depends: 499)
- **87** [RESEARCHED] -- Investigate terminal directory change in wezterm
- **78** [PLANNED] -- Fix Himalaya SMTP authentication failure

## Tasks

### 572. Diagnose OpenCode lean routing failure and improve agent system
- **Effort**: medium
- **Status**: [NOT STARTED]
- **Task Type**: meta

**Description**: Diagnose why `/implement 129` in /home/benjamin/Projects/ProofChecker/ invoked a general implementation agent instead of a lean implementation agent (output logged to ~/.config/nvim/.opencode/output/implement.md). Use this failure to identify all related issues in the OpenCode agent system routing, task type detection, and extension loading to improve reliability

### 571. Create guide for using Discord to manage OpenCode agents from Neovim
- **Effort**: 2-3 hours
- **Status**: [PLANNED]
- **Task Type**: general
- **Research**: [571_create_guide_discord_opencode_agents_neovim/reports/01_discord-opencode-guide.md]
- **Plan**: [571_create_guide_discord_opencode_agents_neovim/plans/01_discord-opencode-guide.md]

**Description**: Create a workflow guide in `/home/benjamin/.config/nvim/.opencode/docs/guides/` for using Discord to manage OpenCode agents. Reference `/home/benjamin/.dotfiles/docs/discord-bot.md` which outlines the existing NixOS Discord bot setup. Research how to use these resources from within Neovim, describing the most convenient and low-friction workflow for everyday use.

### 568. Update artifact formats for deviation tracking
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [568_update_artifact_formats_deviation_tracking/reports/01_artifact-formats-research.md]
- **Summary**: [568_update_artifact_formats_deviation_tracking/summaries/01_artifact-formats-summary.md]
- **Plan**: [568_update_artifact_formats_deviation_tracking/plans/01_artifact-formats-plan.md]

**Description**: Add deviation tracking fields to core artifact formats: `handoff-artifact.md` (new `## Deviations from Plan` section), `summary-format.md` (new `## Plan Deviations` section), `progress-file.md` (`deviations` array in schema), `context-exhaustion-detection.md` (final checkpoint protocol — update both progress file AND plan file as last actions before writing handoff when exhaustion is imminent), and `plan-format-enforcement.md` (deviation annotation requirements). These format changes define the contract that tasks 569 and 570 implement.
  - **Target files**: `.claude/context/formats/handoff-artifact.md`, `.claude/context/formats/summary-format.md`, `.claude/context/formats/progress-file.md`, `.claude/context/patterns/context-exhaustion-detection.md`, `.claude/rules/plan-format-enforcement.md`

---

### 569. Enhance general implementation agent with post-phase self-review and deviation tracking
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: 568
- **Research**: [569_enhance_general_implementation_agent/reports/01_agent-enhancement-research.md]
- **Summary**: [569_enhance_general_implementation_agent/summaries/01_agent-enhancement-summary.md]
- **Plan**: [569_enhance_general_implementation_agent/plans/01_agent-enhancement-plan.md]

**Description**: Enhance `general-implementation-agent.md` with four improvements: (1) **Post-phase self-review** (new Stage 4D-ii) — after marking a phase `[COMPLETED]`, re-read the phase subtask list and verify each objective was addressed, noting any skipped items before proceeding to the next phase; (2) **Progressive handoff updates** — update the handoff document incrementally as each phase completes, not only at context exhaustion, so the handoff is always current; (3) **Deviation annotation in plan** — when deviating from plan, annotate the checklist item inline (e.g. `- [x] Task: ... *(deviation: used approach B instead of A — reason)*`); (4) **Final context-exhaustion checkpoint** — when detecting imminent exhaustion, update both progress file AND plan file as last actions before writing the handoff.
  - **Target files**: `.claude/agents/general-implementation-agent.md`

---

### 570. Propagate implementation improvements to extension agents
- **Effort**: 2-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: 569
- **Research**: [570_propagate_improvements_extension_agents/reports/01_extension-agents-research.md]
- **Summary**: [570_propagate_improvements_extension_agents/summaries/01_extension-agents-summary.md]
- **Plan**: [570_propagate_improvements_extension_agents/plans/01_extension-agents-plan.md]

**Description**: Propagate the post-phase self-review, deviation tracking, progressive handoff updates, and final context checkpoint improvements from task 569 to all extension implementation agents. Research confirmed these agents are missing most of general-implementation-agent.md's progress tracking, self-review, handoff, and deviation features: `nix-implementation-agent.md` (0 handoff/deviation/self-check mentions), `neovim-implementation-agent.md` (0 matches), `lean-implementation-agent.md` (has some handoff support but lacks post-phase self-review and deviation tracking). Also check for python, web, z3, latex, typst agents if present. Bring each to parity using the updated formats from task 568 and patterns from task 569.
  - **Target files**: `.claude/extensions/*/agents/*-implementation-agent.md` (nix, neovim, lean, and any others present)

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
| 1 | 500 | [RESEARCHED] | /plan 500 |
| 2 | 501 | [PLANNED] | /implement 501 |
| 3 | 87 | [RESEARCHED] | /plan 87 |
| 4 | 78 | [PLANNED] | /implement 78 |

---

## Recently Completed

| Task | Name | Completed |
|------|------|-----------|
| 567 | Apply 564+565 integrity improvements to nvim .opencode/ seed | 2026-05-14 |
| 566 | Port escalation/compliance fixes to .claude/ reference system | 2026-05-14 |
| 565 | Add plan-compliance spot-check gate to lean skill | 2026-05-14 |
| 564 | Add lean agent escalation protocol and vacuous-definition prohibition | 2026-05-14 |
| 563 | Make /consult always create a task automatically | 2026-05-13 |
| 562 | Upgrade consult report to interactive actionable checklist format | 2026-05-13 |
| 561 | Implement tiered model defaults across agent system | 2026-05-13 |
| 560 | Research model routing best practices for agent system | 2026-05-13 |
| 557 | Research lifecycle-aware notification patterns for Claude Code hooks | 2026-05-13 |


## Recommended Order

