---
paths: specs/**/plans/**
---

# Plan Format Checklist

Full specification: `.claude/context/formats/plan-format.md`

**Required metadata fields**: Task, Status, Effort, Dependencies, Research Inputs, Artifacts, Standards, Type (Markdown block, not YAML frontmatter).

**Required sections**: Overview, Goals & Non-Goals, Risks & Mitigations, Implementation Phases, Testing & Validation, Artifacts & Outputs, Rollback/Contingency.

**Phase heading format**: `### Phase N: {name} [STATUS]` -- status lives ONLY in the heading. Valid markers: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETED]`, `[PARTIAL]`, `[BLOCKED]`. No emojis.

**Checklist item annotation format** (when implementing):
- Completed: `- [x] **Task {P}.{N}**: {description} *(completed)*`
- Completed with note: `- [x] **Task {P}.{N}**: {description} *(completed: {brief note})*`
- In progress: `- [ ] **Task {P}.{N}**: {description} *(in progress)*`
- In progress at handoff: `- [ ] **Task {P}.{N}**: {description} *(in progress — handoff)*`

**Deviation annotation format** (when deviating from plan):
- Skipped: `- [ ] **Task {P}.{N}**: {description} *(deviation: skipped — {reason})*`
- Altered: `- [x] **Task {P}.{N}**: {description} *(deviation: altered — {what changed})*`
- Deferred: `- [ ] **Task {P}.{N}**: {description} *(deviation: deferred to task {N})*`
