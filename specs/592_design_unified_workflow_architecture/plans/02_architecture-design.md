# Implementation Plan: Task #592

- **Task**: 592 - Design unified workflow architecture
- **Status**: [PLANNED]
- **Effort**: 3 hours
- **Dependencies**: 591 (satisfied)
- **Research Inputs**: specs/592_design_unified_workflow_architecture/reports/01_seed-research.md, specs/592_design_unified_workflow_architecture/reports/02_architecture-design.md
- **Artifacts**: plans/02_architecture-design.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false

## Overview

This task produces three deliverables that collectively transform the research findings from tasks 591 and 592 into actionable implementation guidance for the downstream task suite (593-599). The primary deliverable is a formal architecture specification document covering all 7 components (shared command infrastructure, shared skill base, /orchestrate state machine, dispatch_agent() abstraction, handoff protocol, extension lifecycle hooks, nested loop resolution). The secondary deliverables update downstream task descriptions to reference specific architecture components and create per-task design guidance reports with concrete specifications (function signatures, schemas, state machine definitions).

### Research Integration

The research report (02_architecture-design.md) provides the complete architectural blueprint: file layouts, function inventories, state machine design, JSON schemas, hook execution contracts, and the exclusive loop model. The seed report (01_seed-research.md) provides the team research synthesis from task 591 with the fork decision matrix, dispatch_agent() abstraction, and handoff protocol findings. Both are fully integrated into this plan.

### Prior Plan Reference

No prior plan.

### Roadmap Alignment

No ROADMAP.md items directly targeted by this design task (meta task type).

### Literature Source Mapping

No literature source referenced.

## Goals & Non-Goals

**Goals**:
- Create a formal architecture specification document that downstream tasks 593-599 reference as their authoritative blueprint
- Update state.json and TODO.md descriptions for tasks 593-599 to reference specific architecture components and be more actionable
- Write design guidance reports (03_design-guidance.md) in each downstream task's reports/ directory with concrete specs: function signatures, JSON schemas, state machine definitions, file locations
- Establish the dependency graph and implementation ordering across the task suite

**Non-Goals**:
- Implementing any of the 7 architecture components (that is tasks 593-599)
- Modifying any command, skill, or agent files
- Creating new shell scripts or code artifacts
- Changing the extension manifest.json schema (task 599 scope)
- Detailed context budget calculations (task 598 scope)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Architecture spec is too abstract for implementers to follow | H | M | Include concrete function signatures, JSON schemas, and file paths in every component section |
| Design guidance reports duplicate information already in the architecture spec | M | M | Guidance reports extract only task-specific sections and add implementation-order details not in the spec |
| Downstream task descriptions become stale if architecture evolves | M | L | Task descriptions reference the architecture spec document as the authoritative source; individual details are secondary |
| state.json update introduces sync issues with TODO.md | M | L | Use the two-phase update pattern: state.json first, TODO.md second, verify both |

## Implementation Phases

**Dependency Analysis**:
| Wave | Phases | Blocked by |
|------|--------|------------|
| 1 | 1 | -- |
| 2 | 2, 3 | 1 |
| 3 | 4 | 2, 3 |

Phases within the same wave can execute in parallel.

### Phase 1: Write architecture design specification [NOT STARTED]

**Goal**: Create the authoritative architecture specification document that all downstream tasks reference. This is the primary deliverable of task 592.

**Tasks**:
- [ ] Create directory `specs/592_design_unified_workflow_architecture/design/`
- [ ] Write `architecture-spec.md` with 7 component sections, each containing:
  - Component purpose and scope
  - File locations (new files to create, existing files to modify)
  - Interface specification (function signatures, JSON schemas, CLI arguments)
  - Interaction with other components (cross-references)
  - Implementation ordering constraints
- [ ] Component 1 (Shared Command Infrastructure): Specify `parse-command-args.sh`, `command-gate-in.sh`, `command-gate-out.sh` with exact function signatures and exported variables from the research report
- [ ] Component 2 (Shared Skill Base): Specify `skill-base.sh` function inventory (11 functions), hook points, target skill sizes from the research
- [ ] Component 3 (/orchestrate State Machine): Specify the state table, transition diagram, MAX_CYCLES=5, loop guard schema, blocker escalation flow
- [ ] Component 4 (dispatch_agent()): Specify the `dispatch-agent.sh` function with the semantic `is_blocker_escalation` flag, future-proofing section
- [ ] Component 5 (Handoff Protocol): Specify `.orchestrator-handoff.json` schema (400-token budget), writing/reading contracts, relationship to continuation handoffs
- [ ] Component 6 (Extension Lifecycle Hooks): Specify manifest.json `hooks` schema additions, hook execution contract (positional args, exit codes, permissions)
- [ ] Component 7 (Nested Loop Resolution): Specify the exclusive loop model, `orchestrator_mode` flag propagation through continuation chains
- [ ] Include the dependency graph (Appendix C from research) and file location summary (Appendix D from research)
- [ ] Include the context budget architecture overview (four-tier model) as a cross-cutting concern

**Timing**: 1 hour

**Depends on**: none

**Files to modify**:
- `specs/592_design_unified_workflow_architecture/design/architecture-spec.md` - NEW: primary architecture specification

**Verification**:
- Document contains all 7 component sections
- Each component has: purpose, file locations, interface spec, cross-references
- Function signatures match research report findings
- JSON schemas are valid and include all fields from research
- Dependency graph matches research Appendix C

---

### Phase 2: Update downstream task descriptions [NOT STARTED]

**Goal**: Make tasks 593-599 descriptions more specific and actionable by referencing concrete architecture components from the specification document.

**Tasks**:
- [ ] Read current state.json descriptions for tasks 593-599
- [ ] For task 593: Update description to reference specific shared scripts by name (`parse-command-args.sh`, `command-gate-in.sh`, `command-gate-out.sh`) and their exact exported variables
- [ ] For task 594: Update description to reference `skill-base.sh` function inventory, hook point locations, and the dependency on task 598 context budgets
- [ ] For task 595: Update description to reference target command sizes (~150-200 lines), the routing-only controller pattern, and what commands retain vs. delegate
- [ ] For task 596: Update description to reference the state machine design, `dispatch-agent.sh`, `.orchestrator-handoff.json` schema, and the `orchestrator_mode` flag
- [ ] For task 597: Update description to reference shared utilities applicable to /task, /revise, /todo, /review
- [ ] For task 598: Update description to reference the four-tier context loading model and budget caps per agent type
- [ ] For task 599: Update description to reference the `hooks` manifest.json schema, extension skill thinning pattern, and documentation update targets
- [ ] Write all 7 updated descriptions to state.json using jq
- [ ] Update corresponding TODO.md entries to match state.json descriptions
- [ ] Verify state.json and TODO.md are synchronized

**Timing**: 45 minutes

**Depends on**: 1

**Files to modify**:
- `specs/state.json` - Update descriptions for tasks 593-599
- `specs/TODO.md` - Update corresponding task entries

**Verification**:
- Each task description references the architecture spec document path
- Each description mentions specific components, file names, or schemas relevant to that task
- state.json and TODO.md descriptions are synchronized
- No task's dependencies changed (only descriptions updated)

---

### Phase 3: Create design guidance reports for downstream tasks [NOT STARTED]

**Goal**: Write `03_design-guidance.md` reports in each downstream task's reports/ directory containing task-specific concrete specifications extracted from the architecture design.

**Tasks**:
- [ ] Task 593 report: Write `specs/593_extract_shared_workflow_utilities/reports/03_design-guidance.md` containing:
  - Full `parse-command-args.sh` specification (signature, algorithm, exported vars)
  - Full `command-gate-in.sh` specification (signature, key behaviors, exported vars)
  - Full `command-gate-out.sh` specification (signature, reading contract)
  - Command refactoring target: what stays in each command file (~150-200 lines), what moves out
  - Baseline measurement methodology notes
- [ ] Task 594 report: Write `specs/594_refactor_workflow_skills_shared_base/reports/03_design-guidance.md` containing:
  - Complete `skill-base.sh` function inventory (11 functions with signatures)
  - Hook point locations in the lifecycle (Stage 2, 4, 6a, 7)
  - Target skill sizes table (researcher 150L, planner 130L, implementer 200L)
  - What remains skill-specific (context collection, delegation context, agent invocation)
- [ ] Task 595 report: Write `specs/595_refactor_research_plan_implement_commands/reports/03_design-guidance.md` containing:
  - Per-command breakdown: what each command retains after extraction
  - Routing-only controller pattern specification
  - Extension routing table integration requirements
  - Context tier constraints (commands must NOT load Tier 3 context)
- [ ] Task 596 report: Write `specs/596_create_orchestrate_command_skill_agent/reports/03_design-guidance.md` containing:
  - Complete state machine state table with transitions
  - `dispatch-agent.sh` full function specification
  - `.orchestrator-handoff.json` schema with all fields
  - Loop guard file schema
  - Blocker escalation flow (the 5-step sequence)
  - `orchestrator_mode` flag propagation pattern
- [ ] Task 597 report: Write `specs/597_refactor_task_revise_todo_review/reports/03_design-guidance.md` containing:
  - Applicable shared utilities from task 593 (gate-in/gate-out patterns)
  - /todo decomposition targets (orphan detection, roadmap sync, vault, metrics)
  - Memory harvest automation specification
  - /review decomposition targets (issue grouping, roadmap integration, tier selection)
- [ ] Task 598 report: Write `specs/598_progressive_disclosure_context_system/reports/03_design-guidance.md` containing:
  - Four-tier loading model specification (tier definitions, budget per tier)
  - Budget caps per agent type (sonnet 8K, opus 15K, haiku 2K)
  - Context index.json audit criteria
  - Tier classification rules for the 97 existing entries
- [ ] Task 599 report: Write `specs/599_update_claudemd_extension_documentation/reports/03_design-guidance.md` containing:
  - manifest.json `hooks` schema definition
  - Extension skill thinning pattern (target 30-50 lines)
  - CLAUDE.md sections requiring update (/orchestrate, routing table, shared utilities)
  - Documentation files requiring update (creating-commands.md, creating-skills.md, creating-agents.md)

**Timing**: 1 hour

**Depends on**: 1

**Files to modify**:
- `specs/593_extract_shared_workflow_utilities/reports/03_design-guidance.md` - NEW
- `specs/594_refactor_workflow_skills_shared_base/reports/03_design-guidance.md` - NEW
- `specs/595_refactor_research_plan_implement_commands/reports/03_design-guidance.md` - NEW
- `specs/596_create_orchestrate_command_skill_agent/reports/03_design-guidance.md` - NEW
- `specs/597_refactor_task_revise_todo_review/reports/03_design-guidance.md` - NEW
- `specs/598_progressive_disclosure_context_system/reports/03_design-guidance.md` - NEW
- `specs/599_update_claudemd_extension_documentation/reports/03_design-guidance.md` - NEW

**Verification**:
- Each report is 80-150 lines of actionable design guidance
- Each report contains concrete specifications (not general summaries)
- Task 593 report includes function signatures matching the architecture spec
- Task 596 report includes the complete state machine and handoff schema
- No report duplicates content already in the task's 01_seed-research.md

---

### Phase 4: Validate consistency and commit [NOT STARTED]

**Goal**: Verify all deliverables exist, are consistent, and commit the work.

**Tasks**:
- [ ] Verify architecture spec file exists and contains all 7 component sections
- [ ] Verify all 7 design guidance reports exist in their respective task directories
- [ ] Verify state.json descriptions for tasks 593-599 were updated
- [ ] Verify TODO.md entries match state.json for tasks 593-599
- [ ] Verify no state.json fields other than `description` were modified (dependencies, status, etc. unchanged)
- [ ] Run a cross-reference check: architecture spec references match guidance report content
- [ ] Git commit all changes

**Timing**: 15 minutes

**Depends on**: 2, 3

**Files to modify**:
- No new files; validation only plus git commit

**Verification**:
- `ls specs/592_design_unified_workflow_architecture/design/architecture-spec.md` succeeds
- `ls specs/59{3,4,5,6,7,8,9}_*/reports/03_design-guidance.md` returns 7 files
- `jq '.active_projects[] | select(.project_number >= 593 and .project_number <= 599) | .description' specs/state.json` shows updated descriptions
- Git commit succeeds with all deliverables included

## Testing & Validation

- [ ] Architecture spec contains all 7 component sections with interface specifications
- [ ] Each component section has: purpose, file locations, function signatures or JSON schemas, cross-references
- [ ] All 7 design guidance reports exist (one per downstream task)
- [ ] Each guidance report is 80-150 lines with concrete, actionable specifications
- [ ] state.json and TODO.md are synchronized for tasks 593-599
- [ ] No downstream task dependencies or statuses were changed
- [ ] Architecture spec dependency graph matches research report Appendix C

## Artifacts & Outputs

- `specs/592_design_unified_workflow_architecture/design/architecture-spec.md` - Primary architecture specification
- `specs/592_design_unified_workflow_architecture/plans/02_architecture-design.md` - This plan
- `specs/593_extract_shared_workflow_utilities/reports/03_design-guidance.md` - Design guidance for task 593
- `specs/594_refactor_workflow_skills_shared_base/reports/03_design-guidance.md` - Design guidance for task 594
- `specs/595_refactor_research_plan_implement_commands/reports/03_design-guidance.md` - Design guidance for task 595
- `specs/596_create_orchestrate_command_skill_agent/reports/03_design-guidance.md` - Design guidance for task 596
- `specs/597_refactor_task_revise_todo_review/reports/03_design-guidance.md` - Design guidance for task 597
- `specs/598_progressive_disclosure_context_system/reports/03_design-guidance.md` - Design guidance for task 598
- `specs/599_update_claudemd_extension_documentation/reports/03_design-guidance.md` - Design guidance for task 599

## Rollback/Contingency

This task produces only documentation artifacts (architecture spec, design guidance reports) and task description updates. Rollback is straightforward:
- Architecture spec: delete `specs/592_design_unified_workflow_architecture/design/` directory
- Design guidance reports: delete `03_design-guidance.md` from each downstream task's reports/ directory
- Task descriptions: revert state.json and TODO.md via git checkout
- No code changes, no configuration changes, no system behavior changes
