# Implementation Plan: Task #555

- **Task**: 555 - Update proof workflow docs with literature-first stages
- **Status**: [NOT STARTED]
- **Effort**: 1 hour
- **Dependencies**: Task #553 (Lean literature fidelity policy), Task #554 (Formal literature fidelity policy)
- **Research Inputs**: specs/555_update_proof_workflow_literature/reports/01_proof-workflow-literature.md
- **Artifacts**: plans/01_proof-workflow-literature.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: true

## Overview

Modify three proof workflow documents to integrate literature-first stages before tactic exploration and automation loops. The research report identified exact insertion points and provides draft content snippets for each change. All three files are in separate extensions (lean and formal), and each references only its own extension's literature fidelity policy. The changes add mode-gated behavior (literature-guided vs. first-principles) without altering existing first-principles workflows.

### Research Integration

The research report (`01_proof-workflow-literature.md`) provides:
- Exact line numbers and insertion points for all 10 changes across 3 files
- Draft content snippets ready for adaptation
- Cross-reference mapping: lean files reference lean policy, formal files reference formal policy
- Confirmation that tactic-patterns.md and verification-workflow.md do NOT need modification
- Risk analysis with mitigations for content bloat and mode confusion

### Prior Plan Reference

No prior plan.

### Roadmap Alignment

No ROADMAP.md found.

## Goals & Non-Goals

**Goals**:
- Add "Stage 1.5: Check for Literature Source" to lean-implementation-flow.md
- Modify Stage 4B proof loop to consult literature before tactic exploration
- Add literature-first prefix to the Tactic Selection Strategy section
- Add "Step 0: Check for Literature Source" to end-to-end-proof-workflow.md
- Modify Step 2 to follow literature structure when provided
- Add literature fidelity policy to context dependencies and success criteria
- Expand "Choose Strategy" in proof-construction.md with literature-guided option
- Modify Phase 1 Sketch to support literature extraction mode

**Non-Goals**:
- Modifying tactic-patterns.md (reference doc, not workflow)
- Modifying verification-workflow.md (already cross-referenced by formal policy)
- Modifying modal-proof-strategies.md or temporal-proof-strategies.md (out of scope)
- Creating new policy documents (already created by tasks 553/554)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Stage 4B becomes too long/complex | M | L | Keep literature consultation step brief, reference full policy for details |
| Agents misinterpret as requiring literature checks in first-principles mode | M | L | Each insertion explicitly gates on "literature-guided mode only" |
| Cross-reference confusion between lean/formal policies | L | L | Each file references only its own extension's policy |

## Implementation Phases

**Dependency Analysis**:
| Wave | Phases | Blocked by |
|------|--------|------------|
| 1 | 1, 2, 3 | -- |

Phases within the same wave can execute in parallel.

### Phase 1: Modify lean-implementation-flow.md [NOT STARTED]

**Goal**: Add literature-first stages to the Lean implementation agent's proof development workflow.

**Tasks**:
- [ ] Insert new "Stage 1.5: Check for Literature Source" section between Stage 1 (Parse Delegation Context, ends ~line 31) and Stage 2 (Load and Parse Implementation Plan, starts ~line 35). Content: scan delegation context for literature references, determine mode, load literature source if present, map source steps to proof development stages. Cross-reference `literature-fidelity-policy.md`.
- [ ] Replace Stage 4B "Execute Proof Development" (lines 69-84) with expanded version that adds step 3 "Consult literature source" (literature-guided mode) between reading the target file and the iterative tactic loop. The existing REPEAT loop becomes step 4 for first-principles mode or when literature step is not applicable.
- [ ] Prefix the "Tactic Selection Strategy" section (lines 142-147) with step 0: "Literature step (literature-guided mode): Follow the tactic/approach prescribed by the source for this step. See `literature-fidelity-policy.md`." Renumber existing steps 1-4 to remain after this new step 0.

**Timing**: 20 minutes

**Depends on**: none

**Files to modify**:
- `.claude/extensions/lean/context/project/lean4/agents/lean-implementation-flow.md` - Add Stage 1.5, modify Stage 4B, prefix Tactic Selection Strategy

**Verification**:
- File contains "Stage 1.5: Check for Literature Source" section
- Stage 4B includes "Consult literature source" step before the REPEAT loop
- Tactic Selection Strategy starts with step 0 for literature-guided mode
- Cross-reference to `literature-fidelity-policy.md` present in all added sections

---

### Phase 2: Modify end-to-end-proof-workflow.md [NOT STARTED]

**Goal**: Add literature-first prerequisite and modify proof outline step in the end-to-end proof workflow.

**Tasks**:
- [ ] Insert new "Step 0: Check for Literature Source" section before Step 1 (State the Theorem, ~line 19). Content: determine whether a literature source is provided, set mode (literature-guided vs. first-principles), extract proof structure from source before proceeding. Cross-reference `literature-fidelity-policy.md`.
- [ ] Modify "Step 2: Outline the Proof" (lines 25-29) to add literature-guided behavior: "In literature-guided mode, extract the outline from the literature source rather than composing one independently." Validation should note that in literature-guided mode the outline should mirror the source's argument structure.
- [ ] Add `literature-fidelity-policy.md` to the "Context Dependencies" section (lines 43-47)
- [ ] Add literature-guided success criterion to the "Success Criteria" section (lines 49-52): "When a literature source is provided, the proof structure mirrors the source."

**Timing**: 15 minutes

**Depends on**: none

**Files to modify**:
- `.claude/extensions/lean/context/project/lean4/processes/end-to-end-proof-workflow.md` - Add Step 0, modify Step 2, update context dependencies and success criteria

**Verification**:
- File contains "Step 0: Check for Literature Source" section
- Step 2 mentions literature-guided mode behavior
- Context Dependencies includes `literature-fidelity-policy.md`
- Success Criteria includes literature-source criterion

---

### Phase 3: Modify proof-construction.md [NOT STARTED]

**Goal**: Add literature-first strategy option to the formal extension's proof construction process.

**Tasks**:
- [ ] Expand "Choose Strategy" section (lines 21-25) to include literature-guided option as the primary choice when a reference proof is provided. Existing strategy options (direct/indirect, forward/backward, induction/case analysis) apply in first-principles mode. Cross-reference formal extension's `literature-fidelity-policy.md`.
- [ ] Modify "Phase 1: Sketch" (within Proof Development Phases, ~lines 27-35) to support both modes: "Write informal proof idea (first-principles) OR extract proof structure from literature source (literature-guided)."
- [ ] Add formal extension's `literature-fidelity-policy.md` to the "References" section (lines 138-143)

**Timing**: 15 minutes

**Depends on**: none

**Files to modify**:
- `.claude/extensions/formal/context/project/logic/processes/proof-construction.md` - Expand Choose Strategy, modify Phase 1 Sketch, add reference

**Verification**:
- Choose Strategy section lists "Literature-guided" as first option
- Phase 1 Sketch supports both first-principles and literature-guided modes
- References section includes `literature-fidelity-policy.md`

## Testing & Validation

- [ ] All 3 modified files parse correctly as valid Markdown
- [ ] Each file contains cross-reference to its extension's `literature-fidelity-policy.md`
- [ ] Literature-guided behavior is explicitly gated (no unconditional literature checks)
- [ ] Existing first-principles workflow logic is preserved unchanged
- [ ] No references to the wrong extension's policy (lean files -> lean policy, formal files -> formal policy)

## Artifacts & Outputs

- `specs/555_update_proof_workflow_literature/plans/01_proof-workflow-literature.md` (this file)
- Modified: `.claude/extensions/lean/context/project/lean4/agents/lean-implementation-flow.md`
- Modified: `.claude/extensions/lean/context/project/lean4/processes/end-to-end-proof-workflow.md`
- Modified: `.claude/extensions/formal/context/project/logic/processes/proof-construction.md`

## Rollback/Contingency

All changes are additions or expansions to existing Markdown documents. Rollback via `git checkout` of the three modified files. No schema changes, no index modifications, no build artifacts.
