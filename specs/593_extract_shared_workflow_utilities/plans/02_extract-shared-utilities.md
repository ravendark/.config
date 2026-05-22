# Implementation Plan: Extract Shared Workflow Utilities

- **Task**: 593 - Extract shared workflow utilities
- **Status**: [IMPLEMENTING]
- **Effort**: 7 hours
- **Dependencies**: 592 (design, satisfied)
- **Research Inputs**: reports/02_team-research.md, reports/03_design-guidance.md, reports/01_seed-research.md
- **Artifacts**: plans/02_extract-shared-utilities.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false

## Overview

Extract ~390 lines of duplicated command logic from `.claude/commands/{research,plan,implement}.md` into 4 reusable shell scripts in `.claude/scripts/`. The scripts are `parse-command-args.sh` (arg parsing + flags), `command-gate-in.sh` (session generation + task lookup + terminal guard), `command-gate-out.sh` (defensive status correction), and `postflight-workflow.sh` (unified postflight replacing 3 near-identical scripts). After extraction, each command file shrinks from ~500-612 lines to ~250-280 lines (~45-50% reduction). The 150-200 line target is achievable only after task 595.

### Research Integration

Key findings integrated from team research (4 teammates, high confidence):

1. **4-script decomposition confirmed optimal** -- alternatives (3-script merged, 5-script split, monolith) rejected for clear architectural reasons.
2. **Source vs subprocess convention**: `parse-command-args.sh` and `command-gate-in.sh` must use `source` (not subprocess) because they export variables. `command-gate-out.sh` and `postflight-workflow.sh` use subprocess-call. This departs from codebase convention and must be documented.
3. **Flag parsing uses superset approach**: parse ALL flags unconditionally, export all. Each command uses only what it needs. Per-command post-clamp for team-size max (3 for plan, 4 for research/implement).
4. **GATE OUT extraction is narrow**: only the defensive correction pattern (~25 lines) is extractable. Implement-specific steps (completion_summary, plan file verify, TODO summary) stay inline.
5. **Existing postflight scripts are dead code** (zero grep references from skills) but architecturally important as the dependency for task 594's `skill-base.sh`.
6. **Multi-task dispatch blocks (~115-147 lines) are NOT extractable** in task 593 -- they are the largest non-extractable section and explain the 250-280 line landing zone.
7. **jq `!=` escaping**: gate-out defensive correction must use `select(.status == "X" | not)` pattern.

### Prior Plan Reference

No prior plan.

### Roadmap Alignment

No ROADMAP.md items are directly advanced by this meta task. This task implements Component 1 of the unified workflow architecture (architecture-spec.md), which is infrastructure work.

### Literature Source Mapping

No literature source referenced.

## Goals & Non-Goals

**Goals**:
- Create 4 shell scripts in `.claude/scripts/` that encapsulate shared command logic
- Migrate all 3 command files to source/call these scripts, eliminating ~390 lines of duplication
- Establish baseline line measurements before extraction and verify reduction after
- Convert 3 existing near-identical postflight scripts into thin wrappers calling unified `postflight-workflow.sh`
- Document the `source` convention departure for scripts that export variables

**Non-Goals**:
- Extracting multi-task dispatch logic (reserved for task 595)
- Extracting extension routing lookup (reserved for task 595)
- Creating `skill-base.sh` (reserved for task 594)
- Reaching the 150-200 line target per command (achievable only after task 595)
- Modifying any skill files (skills are task 594's scope)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Source convention confusion: LLM interprets `source` as shell-level sourcing across tool calls | H | M | Document that all sourcing + variable usage happens in a single Bash tool call; add header comments |
| Flag parsing edge cases in superset approach | M | L | Test with all flag combinations; per-command post-clamp handles divergences |
| Backward compatibility break if external callers reference old postflight scripts | M | L | Keep old scripts as thin wrappers; defer deletion to task 599 |
| jq `!=` escaping bug in gate-out defensive correction | H | M | Use `select(.status == "X" | not)` pattern per Issue #1132 workaround |
| `specs/tmp/` directory missing in fresh checkouts | L | M | Add `mkdir -p specs/tmp` guard in postflight-workflow.sh |

## Implementation Phases

**Dependency Analysis**:
| Wave | Phases | Blocked by |
|------|--------|------------|
| 1 | 1 | -- |
| 2 | 2 | 1 |
| 3 | 3 | 2 |
| 4 | 4 | 3 |
| 5 | 5 | 4 |

Phases are fully sequential. Each phase builds on the previous one's scripts/migrations.

---

### Phase 1: Baseline Measurements and Core Parsing Script [COMPLETED]

**Goal**: Establish before-measurements for all command files and create `parse-command-args.sh` -- the highest-savings, lowest-risk extraction target.

**Tasks**:
- [x] Record baseline line counts for all 3 command files (`wc -l` on research.md, plan.md, implement.md) *(completed: research.md=500, plan.md=531, implement.md=612)*
- [x] Record baseline line counts for the 3 existing postflight scripts *(completed: all three are 69 lines)*
- [x] Diff the `parse_task_args()` blocks across all 3 commands to confirm byte-identical duplication *(completed: blocks are structurally identical)*
- [x] Create `.claude/scripts/parse-command-args.sh` implementing the superset flag parser per design-guidance.md specification *(completed)*
- [x] Include all exports: TASK_NUMBERS, REMAINING_ARGS, TEAM_MODE, TEAM_SIZE, EFFORT_FLAG, MODEL_FLAG, CLEAN_FLAG, FORCE_FLAG, FOCUS_PROMPT *(completed)*
- [x] Add documentation header explaining the `source` convention (must be sourced, not called as subprocess, within a single Bash tool invocation) *(completed)*
- [x] Make script executable (`chmod +x`) *(completed)*
- [x] Test the script standalone with representative inputs: `"593"`, `"7, 22-24, 59 --team --team-size 3"`, `"42 focus on APIs --fast --haiku"`, `"100 --force --clean"` *(completed: all 6 test cases pass)*

**Timing**: 1.5 hours

**Depends on**: none

**Files to modify**:
- `.claude/scripts/parse-command-args.sh` - CREATE: superset arg parser (~50-60 lines)

**Verification**:
- Script parses all flag combinations correctly
- Exports match the specification in design-guidance.md
- Header comment documents source convention

---

### Phase 2: Gate Scripts (gate-in and gate-out) [NOT STARTED]

**Goal**: Create `command-gate-in.sh` (session generation, task lookup, terminal guard) and `command-gate-out.sh` (defensive status correction).

**Tasks**:
- [ ] Create `.claude/scripts/command-gate-in.sh` with `gate_in()` function per design-guidance.md
- [ ] Implement SESSION_ID generation: `sess_$(date +%s)_$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n')`
- [ ] Implement task lookup via jq on state.json, exporting TASK_TYPE, TASK_STATUS, PROJECT_NAME, DESCRIPTION, PADDED_NUM
- [ ] Implement terminal status guard (completed, abandoned, expanded -> exit 1)
- [ ] Add documentation header explaining source convention
- [ ] Create `.claude/scripts/command-gate-out.sh` with `gate_out()` function
- [ ] Implement defensive status correction using `select(.status == "X" | not)` jq pattern (not `!=`)
- [ ] Include non-blocking artifact validation via `validate-artifact.sh --fix`
- [ ] Keep gate-out scope narrow: only the shared defensive correction pattern (~25 lines). Do NOT include implement-specific completion_summary or plan-specific plan file verification
- [ ] Make both scripts executable
- [ ] Test gate-in with valid task, terminal-status task, and non-existent task
- [ ] Test gate-out with stale status scenario

**Timing**: 1.5 hours

**Depends on**: 1

**Files to modify**:
- `.claude/scripts/command-gate-in.sh` - CREATE: session + task lookup (~45 lines)
- `.claude/scripts/command-gate-out.sh` - CREATE: defensive correction (~30 lines)

**Verification**:
- gate-in exports all required variables
- gate-in rejects terminal statuses with clear error
- gate-out uses safe jq pattern (no `!=` operator)
- Both scripts have documentation headers

---

### Phase 3: Unified Postflight Script [NOT STARTED]

**Goal**: Create `postflight-workflow.sh` that parameterizes the 3 near-identical existing postflight scripts, then convert the old scripts to thin wrappers.

**Tasks**:
- [ ] Diff the 3 existing postflight scripts to confirm they differ only in 7 string constants (status value, artifact type, timestamp field name)
- [ ] Create `.claude/scripts/postflight-workflow.sh` accepting parameters: `TASK_NUMBER ARTIFACT_PATH [ARTIFACT_SUMMARY] OPERATION_TYPE`
- [ ] OPERATION_TYPE maps to: research->researched/research, plan->planned/plan, implement->implemented/summary
- [ ] Include `mkdir -p specs/tmp` guard at top of script
- [ ] Use the two-step jq pattern from existing scripts (Issue #1132 compatible)
- [ ] Convert `postflight-research.sh` to thin wrapper: call `postflight-workflow.sh "$@" "research"`
- [ ] Convert `postflight-plan.sh` to thin wrapper: call `postflight-workflow.sh "$@" "plan"`
- [ ] Convert `postflight-implement.sh` to thin wrapper: call `postflight-workflow.sh "$@" "implement"`
- [ ] Add comment in each wrapper noting it exists for backward compatibility until task 599
- [ ] Make postflight-workflow.sh executable
- [ ] Test with a mock task number to verify jq operations work correctly

**Timing**: 1 hour

**Depends on**: 2

**Files to modify**:
- `.claude/scripts/postflight-workflow.sh` - CREATE: unified postflight (~75 lines)
- `.claude/scripts/postflight-research.sh` - MODIFY: thin wrapper (~10 lines)
- `.claude/scripts/postflight-plan.sh` - MODIFY: thin wrapper (~10 lines)
- `.claude/scripts/postflight-implement.sh` - MODIFY: thin wrapper (~10 lines)

**Verification**:
- Unified script handles all 3 operation types correctly
- Old wrapper scripts produce identical behavior to original implementations
- `specs/tmp/` guard prevents errors on fresh checkouts

---

### Phase 4: Command File Migration [NOT STARTED]

**Goal**: Migrate all 3 command files to use the shared scripts, eliminating duplicated logic. Follow incremental order: research.md first (simplest, 500L), plan.md second (531L), implement.md last (612L, most complex).

**Tasks**:
- [ ] **Migrate research.md**:
  - Replace inline `parse_task_args()` and `parse_ranges()` with reference to `source .claude/scripts/parse-command-args.sh "$ARGUMENTS"`
  - Replace inline GATE IN (session ID, task lookup, terminal guard) with reference to `source .claude/scripts/command-gate-in.sh "$task_number" "research"`
  - Replace inline STAGE 1.5 flag parsing with note that flags are already parsed by parse-command-args.sh
  - Add team-size post-clamp: `[ "$TEAM_SIZE" -gt 4 ] && TEAM_SIZE=4` (research max is 4)
  - Replace inline GATE OUT defensive correction with reference to `bash .claude/scripts/command-gate-out.sh "$task_number" "research" "$SESSION_ID"`
  - Keep inline: multi-task dispatch block, extension routing table, skill invocation, git commit, error handling, anti-bypass constraint
  - Verify line count reduction
- [ ] **Migrate plan.md**:
  - Same parse/gate-in/gate-out replacement pattern as research.md
  - Add team-size post-clamp: `[ "$TEAM_SIZE" -gt 3 ] && TEAM_SIZE=3` (plan max is 3)
  - Keep `--roadmap` flag handling inline (plan-specific)
  - Keep inline: multi-task dispatch, skill routing, plan-specific GATE OUT steps (plan file verification), prior plan discovery
  - Verify line count reduction
- [ ] **Migrate implement.md**:
  - Same parse/gate-in/gate-out replacement pattern
  - Add team-size post-clamp: `[ "$TEAM_SIZE" -gt 4 ] && TEAM_SIZE=4`
  - Keep `--force` flag handling inline (implement-specific gate-in override)
  - Keep inline: multi-task dispatch, continuation loop, implement-specific GATE OUT (completion_summary, TODO summary line), `--force` status override
  - Verify line count reduction
- [ ] Verify all 3 command files retain their YAML frontmatter, anti-bypass constraints, and error handling sections unchanged

**Timing**: 2 hours

**Depends on**: 3

**Files to modify**:
- `.claude/commands/research.md` - MODIFY: replace ~130 lines of inline logic with script references
- `.claude/commands/plan.md` - MODIFY: replace ~130 lines of inline logic with script references
- `.claude/commands/implement.md` - MODIFY: replace ~130 lines of inline logic with script references

**Verification**:
- Each command file is ~250-280 lines (down from 500-612)
- YAML frontmatter, anti-bypass constraint, and error handling sections are intact
- Multi-task dispatch blocks remain inline and unchanged
- Extension routing (research.md) remains inline

---

### Phase 5: Validation and Documentation [NOT STARTED]

**Goal**: Verify all measurements, run end-to-end functional tests, and document the extraction for downstream tasks (594, 595).

**Tasks**:
- [ ] Record post-extraction line counts for all 3 command files and compare to baseline
- [ ] Calculate actual line reduction percentage per command
- [ ] Verify each new script exists, is executable, and has documentation headers
- [ ] Verify old postflight wrappers still work by checking they call postflight-workflow.sh
- [ ] Run a functional test: execute `source .claude/scripts/parse-command-args.sh "593 --team --fast"` and verify exports
- [ ] Run a functional test: execute `source .claude/scripts/command-gate-in.sh "593" "research"` against current state.json
- [ ] Verify no dead code was introduced (no orphaned functions in command files)
- [ ] Add a brief comment at the top of each new script noting which tasks depend on it (task 594 depends on postflight-workflow.sh; task 595 depends on further command slimming)
- [ ] Verify that command files reference scripts using the correct relative path convention (`.claude/scripts/` prefix)

**Timing**: 1 hour

**Depends on**: 4

**Files to modify**:
- `.claude/scripts/parse-command-args.sh` - MODIFY: add downstream dependency comments if not already present
- `.claude/scripts/command-gate-in.sh` - MODIFY: add downstream dependency comments if not already present
- `.claude/scripts/command-gate-out.sh` - MODIFY: add downstream dependency comments if not already present
- `.claude/scripts/postflight-workflow.sh` - MODIFY: add downstream dependency comments if not already present

**Verification**:
- Line counts: research.md ~250-280, plan.md ~260-290, implement.md ~280-310 (implement is larger due to continuation loop and --force logic)
- All 4 new scripts are executable and documented
- Old postflight scripts are thin wrappers
- Functional tests pass

## Testing & Validation

- [ ] parse-command-args.sh handles edge cases: no flags, all flags, ranges, single task, focus prompt with spaces
- [ ] command-gate-in.sh correctly rejects terminal-status tasks
- [ ] command-gate-in.sh generates valid SESSION_ID format (sess_{digits}_{hex})
- [ ] command-gate-out.sh uses safe jq pattern (no `!=` operator)
- [ ] postflight-workflow.sh handles all 3 operation types (research, plan, implement)
- [ ] All 3 command files parse correctly as markdown (YAML frontmatter intact)
- [ ] Baseline vs post-extraction line counts show ~45-50% reduction
- [ ] Old postflight wrapper scripts produce identical behavior via thin-wrapper delegation

## Artifacts & Outputs

- `.claude/scripts/parse-command-args.sh` - New shared arg parser
- `.claude/scripts/command-gate-in.sh` - New shared gate-in script
- `.claude/scripts/command-gate-out.sh` - New shared gate-out script
- `.claude/scripts/postflight-workflow.sh` - New unified postflight script
- `.claude/commands/research.md` - Modified (slimmed) command file
- `.claude/commands/plan.md` - Modified (slimmed) command file
- `.claude/commands/implement.md` - Modified (slimmed) command file
- `.claude/scripts/postflight-research.sh` - Modified to thin wrapper
- `.claude/scripts/postflight-plan.sh` - Modified to thin wrapper
- `.claude/scripts/postflight-implement.sh` - Modified to thin wrapper

## Rollback/Contingency

All changes are to `.claude/` infrastructure files tracked in git. If the extraction causes command failures:

1. **Per-file rollback**: `git checkout HEAD -- .claude/commands/{file}.md` restores any individual command
2. **Full rollback**: `git revert {commit}` reverts the entire extraction
3. **Incremental safety**: Because commands are migrated one at a time (research first, implement last), a failure in one command does not affect the others. The failing command can be reverted independently while the others remain migrated.
4. **Postflight wrappers**: Old scripts are never deleted (thin wrappers preserve backward compatibility), so any callers continue to work.
