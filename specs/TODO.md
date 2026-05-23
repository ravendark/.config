---
next_project_number: 608
---

# TODO

## Task Order

*Updated 2026-05-23. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,610 | -- | -- |

**Grouped by Topic** (indented = depends on parent):

### Uncategorized

78 [PLANNED] — fix_himalaya_smtp_authentication_failure
87 [RESEARCHED] — investigate_wezterm_terminal_directory_change
610 [RESEARCHED] — sweep_skills_context_protection

## Tasks

### 608. Define context-protective lead pattern
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None
- **Research**: [608_context_protective_lead_pattern/reports/01_context-protective-lead.md]
- **Plan**: [608_context_protective_lead_pattern/plans/01_context-protective-plan.md]
- **Summary**: [608_context_protective_lead_pattern/summaries/01_context-protective-summary.md]

**Description**: Create a pattern document and standard that establishes how lead/orchestrator agents should protect their context window. Core principles: (1) never Read large files directly — use jq/Bash one-liners to extract specific fields, (2) fork cheap investigation agents when in-depth information is needed, receiving back short reports (<200 words), (3) lead's context budget target: <10k tokens above baseline for routing and delegation work. Document anti-patterns (reading full state.json, loading format specs, eagerly reading context files) and the correct alternatives (jq extraction, scout forks, passing @-references to subagents instead of reading them yourself). This becomes the reference standard for tasks 609 and 610.

---

### 609. Refactor skill-team-research for context protection
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: 608
- **Research**:
  - [609_refactor_team_research_context_protection/reports/01_context-protection-research.md]
  - [609_refactor_team_research_context_protection/reports/02_synthesis-architecture-analysis.md]
- **Plan**: [609_refactor_team_research_context_protection/plans/01_context-protection-plan.md]
- **Summary**: [609_refactor_team_research_context_protection/summaries/01_context-protection-summary.md]

**Description**: Refactor skill-team-research (currently 751 lines, ~3,900 tokens) as the reference implementation of the context-protective lead pattern from task 608. Replace direct Read operations with jq extractions for state.json lookups. Replace eager context loading (index.json queries, domain context reads, memory retrieval) with fork agents that investigate and return compact summaries. Replace inline teammate output reading with a fork "synthesis agent" that reads all findings and writes the unified report. Target: lead's added context stays under 10k tokens beyond baseline, down from current ~50-60k. The skill file itself should also shrink by moving stage documentation to reference files.

---

### 610. Apply context-protective pattern to remaining skills
- **Effort**: TBD
- **Status**: [RESEARCHED]
- **Task Type**: meta
- **Dependencies**: 608, 609
- **Research**: [610_sweep_skills_context_protection/reports/01_team-research.md]

**Description**: Sweep all remaining skills that accumulate excessive lead context and apply the context-protective lead pattern from task 608, using task 609's refactored skill-team-research as the reference implementation. Priority targets: skill-researcher (242 lines — reads report-format.md, memory, state.json), skill-implementer (363 lines), skill-planner (215 lines), skill-orchestrator (128 lines — reads full state.json and TODO.md), skill-team-plan (598 lines), skill-team-implement (677 lines). For each skill: replace direct file reads with jq extractions, delegate investigation to fork agents, pass format references to subagents instead of reading them into the lead.

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

