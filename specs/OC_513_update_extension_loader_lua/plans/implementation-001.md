# Implementation Plan: Extension Loader Verification

- **Task**: 513 - update_extension_loader_lua
- **Status**: [NOT STARTED]
- **Effort**: 1.5 hours
- **Dependencies**: None
- **Research Inputs**: Research confirmed feature parity exists; implementation already correct
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

This task verifies that the OpenCode extension loader Lua code achieves feature parity with the Claude extension loader. Research confirmed the implementation is already correct - the shared extensions architecture, agent paths, and manifest merging work as intended. The focus is on comprehensive testing to validate functionality.

### Research Integration

Research findings confirm:
- Feature parity: OpenCode uses the same shared extensions architecture as Claude
- Agent path correctly configured to `agent/subagents/`
- Manifest merge targets use `opencode_md` key correctly
- Picker behavior documented: All artifact sections display when extensions loaded

## Goals & Non-Goals

**Goals**:
- Verify `<leader>ao` picker displays all artifact sections correctly
- Confirm extension loading works with shared extensions
- Validate agent installation from extensions
- Test manifest parsing and merging

**Non-Goals**:
- No code changes required (implementation already correct)
- No refactoring of existing loader logic
- No new features or enhancements

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Test environment differs from production | Medium | Low | Test on clean Neovim instance with minimal config |
| Extensions fail to load silently | Medium | Low | Add explicit error checking during tests |
| Manifest parsing edge cases | Low | Low | Test with various extension manifests |

## Implementation Phases

**Dependency Analysis**:
| Wave | Phases | Blocked by |
|------|--------|------------|
| 1 | 1 | -- |
| 2 | 2 | 1 |
| 3 | 3 | 2 |

Phases within the same wave can execute in parallel.

### Phase 1: Test Environment Setup [NOT STARTED]

**Goal**: Prepare isolated test environment for extension loader verification

**Tasks**:
- [ ] Create test configuration directory structure
- [ ] Copy minimal OpenCode extension loader code
- [ ] Set up test extensions with representative manifests
- [ ] Verify Neovim can load test configuration

**Timing**: 20 minutes

**Depends on**: none

**Verification**:
- `:checkhealth` reports no critical errors
- Test extensions are loadable

---

### Phase 2: Picker Behavior Testing [NOT STARTED]

**Goal**: Verify `<leader>ao` picker displays all artifact sections when extensions loaded

**Tasks**:
- [ ] Load OpenCode extension loader
- [ ] Press `<leader>ao` to open artifact picker
- [ ] Verify all sections display: context, skills, agents, commands, rules
- [ ] Check that extension artifacts appear in picker
- [ ] Document picker behavior with screenshots/logs

**Timing**: 30 minutes

**Depends on**: 1

**Verification**:
- Picker opens without errors
- All expected sections are visible
- Extension artifacts are accessible

---

### Phase 3: Extension Loading & Manifest Testing [NOT STARTED]

**Goal**: Validate extension loading, agent installation, and manifest parsing

**Tasks**:
- [ ] Test loading extensions from `.opencode/extensions/`
- [ ] Verify agent installation to correct path
- [ ] Test manifest merge with `opencode_md` key
- [ ] Confirm shared extensions work between Claude and OpenCode
- [ ] Run edge case tests (empty manifest, missing keys, malformed JSON)

**Timing**: 40 minutes

**Depends on**: 2

**Verification**:
- Extensions load without errors
- Agents install to `agent/subagents/`
- Manifests merge correctly
- Error handling works for edge cases

## Testing & Validation

- [ ] Picker displays all artifact sections (`<leader>ao`)
- [ ] Extension loading from `.opencode/extensions/`
- [ ] Agent installation to `agent/subagents/`
- [ ] Manifest parsing with `opencode_md` key
- [ ] Shared extensions work with Claude loader
- [ ] Edge cases: empty manifests, missing keys, malformed JSON
- [ ] Error messages are informative

## Artifacts & Outputs

- Test results documentation
- Verification report confirming feature parity
- plans/implementation-001.md (this file)

## Rollback/Contingency

Since no code changes are being made, no rollback is required. If issues are discovered during testing:
1. Document the discrepancy from expected behavior
2. File a new task for the specific issue
3. This task can be marked as verified (current implementation is baseline)

## Notes

- Research confirmed: **No code changes required**
- The implementation already achieves feature parity
- Focus is purely on verification and documentation
- If bugs are found, they represent pre-existing issues to be addressed separately