---
next_project_number: 584
---

# TODO

## Task Order

*Updated 2026-05-15. 9 active tasks remaining.*

### Wave 1 (no dependencies)
- **579** [COMPLETED] -- Port generate-task-order.sh + task-order-format.md
- **580** [COMPLETED] -- Port topic schema & rules

### Wave 2 (depends on Wave 1)
- **581** [PLANNED] -- Port update-task-status.sh Phase 3 rewrite (depends: 579)
- **582** [PLANNED] -- Port command integration: task.md, todo.md, review.md (depends: 579, 580)
- **583** [PLANNED] -- Port agent & skill integration (depends: 579, 580)

### Pending (pre-existing)
- **500** [RESEARCHED] -- Add context: fork frontmatter to core delegating skills (depends: 499)
- **501** [PLANNED] -- Optimize team-mode skills for FORK_SUBAGENT parallel cache sharing (depends: 499)
- **87** [RESEARCHED] -- Investigate terminal directory change in wezterm
- **78** [PLANNED] -- Fix Himalaya SMTP authentication failure

## Tasks

### 579. Port generate-task-order.sh and task-order-format.md
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [579_port_task_order_script/reports/01_port-task-order.md]
- **Plan**: [579_port_task_order_script/plans/01_port-task-order.md]
- **Summary**: [579_port_task_order_script/summaries/01_port-task-order-summary.md]

**Description**: Port generate-task-order.sh (834 lines) from ProofChecker with generalized topic heuristic. Rewrite task-order-format.md from flat categories to wave+tree+topic format. The script uses Kahn's algorithm for dependency waves, DFS for tree rendering, and atomic TODO.md section replacement. Generalize assign_topic_heuristic() to remove ProofChecker-specific keywords — either make it read a project-local config or rely solely on state.json active_topics. Replace ProofChecker-specific examples in format doc with generic ones.

**Source reference**: ProofChecker task 149 (redesign_task_order_format)

---

### 580. Port topic schema and rules
- **Effort**: 30-60 min
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [580_port_topic_schema_rules/reports/01_port-topic-schema.md]
- **Plan**: [580_port_topic_schema_rules/plans/01_port-topic-schema.md]
- **Summary**: [580_port_topic_schema_rules/summaries/01_port-topic-schema-summary.md]

**Description**: Port topic system schema and rules from ProofChecker. Add active_topics (top-level string[]) and per-task topic (string, optional) fields to state-management-schema.md. Add Task Order Synchronization section (+49 lines) to state-management.md rule documenting derivation relationships, regeneration triggers, responsible scripts, and non-regeneration events.

**Source reference**: ProofChecker tasks 150/152

---

### 581. Port update-task-status.sh Phase 3 rewrite
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: meta
- **Dependencies**: Task #579
- **Research**: [581_port_status_script_phase3/reports/01_port-status-phase3.md]
- **Plan**: [581_port_status_script_phase3/plans/01_port-status-phase3.md]

**Description**: Port update-task-status.sh Phase 3 rewrite from ProofChecker. Replace current Phase 3 with two-mode strategy: Mode A (in-place sed for non-terminal status changes — fast, no full regen) + Mode B (full regeneration via generate-task-order.sh for terminal transitions COMPLETED/ABANDONED/EXPANDED). Add Mode A fallback to regen if task not found in tree. Preserve nvim-config-specific Phase 5 lifecycle notifications (TTS, WezTerm tab colors, OpenCode session renaming).

**Source reference**: ProofChecker task 150 (task_order_auto_sync)

---

### 582. Port command integration (task.md, todo.md, review.md)
- **Effort**: 2-3 hours
- **Status**: [PLANNED]
- **Task Type**: meta
- **Dependencies**: Task #579, Task #580
- **Research**: [582_port_command_integration/reports/01_port-command-integration.md]
- **Plan**: [582_port_command_integration/plans/01_port-command-integration.md]

**Description**: Port task order auto-sync and topic support into task.md, todo.md, and review.md commands. task.md: add Step 4.5 topic picker (generalized — read active_topics from state.json, no hardcoded keywords), Part C regen call, topic inheritance in expand/sync/review modes, topic backfill in sync mode. todo.md: add Step 5.8 post-archival regen and Step 5.8.8a post-vault regen. review.md: replace ~330 lines of manual Task Order management (sections 6.5-6.7) with single generate-task-order.sh call, generalize topic inference to use extension-aware path matching instead of .lean-specific heuristics.

**Source reference**: ProofChecker tasks 150-152

---

### 583. Port agent and skill integration
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: meta
- **Dependencies**: Task #579, Task #580
- **Research**: [583_port_agent_skill_integration/reports/01_port-agent-skill.md]
- **Plan**: [583_port_agent_skill_integration/plans/01_port-agent-skill.md]

**Description**: Port topic support into meta-builder-agent.md and skills. meta-builder-agent.md: add Topic column to Stage 5 confirmation table and topic field in Stage 6 state.json entry. skill-fix-it: add Step 9.1 topic auto-inference (generalized — .claude/specs/ -> agent-system, extension-aware for other paths, no .lean-specific heuristic). skill-todo: add Stage 10.5 RegenerateTaskOrder (call generate-task-order.sh after archival + post-vault re-run).

**Source reference**: ProofChecker tasks 151-152

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
| 578 | Fix OpenCode /tmp/ file usage root cause everywhere | 2026-05-15 |
| 577 | Investigate .opencode/ output path corruption after extension reload | 2026-05-15 |
| 576 | Fix OpenCode session picker restore/browse options | 2026-05-15 |
| 575 | Audit OpenCode session picker failure modes | 2026-05-15 |
| 574 | Fix temp file usage in .opencode/ agent system | 2026-05-14 |
| 572 | Diagnose OpenCode lean routing failure | 2026-05-14 |
| 571 | Create guide for Discord to manage OpenCode agents | 2026-05-14 |
| 570 | Propagate improvements to extension agents | 2026-05-14 |
| 569 | Enhance general implementation agent | 2026-05-14 |
| 568 | Update artifact formats for deviation tracking | 2026-05-14 |

