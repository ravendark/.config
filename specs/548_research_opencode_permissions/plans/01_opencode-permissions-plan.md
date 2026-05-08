# Implementation Plan: Configure OpenCode Permissions

- **Task**: 548 - research_opencode_permissions
- **Status**: [NOT STARTED]
- **Effort**: 2 hours
- **Dependencies**: None
- **Research Inputs**: specs/548_research_opencode_permissions/reports/01_opencode-permissions-research.md
- **Artifacts**: plans/01_opencode-permissions-plan.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta

## Overview

Configure the OpenCode permission system by creating an `opencode.json` at the project root that auto-approves edits within the workspace while requiring prompts for external directory access. Migrate remaining `/tmp/opencode/` references in hook scripts and agent instructions to `specs/tmp/`, aligning with the established project convention. Document the dual-permission-system architecture (Claude Code + OpenCode) for future maintainers.

The research report identified that no `opencode.json` exists, `external_directory` defaults to `ask` (causing the user's prompt fatigue), and three remaining `/tmp/` references in `tts-notify.sh` can be relocated entirely within the project root to avoid external_directory prompts.

### Research Integration

Key findings from `01_opencode-permissions-research.md` integrated into this plan:
- OpenCode permission model uses `edit: "allow"` + `external_directory: "ask"` as the target configuration
- Project already uses `specs/tmp/` for 350+ temp file references; only `tts-notify.sh` still uses `/tmp/`
- Agent instructions in `general-research-agent.md` reference `/tmp/opencode/` but should reference `specs/tmp/`
- The project has two parallel permission systems (Claude Code `.opencode/settings.json` and OpenCode `opencode.json`) that serve different purposes
- Per-agent permission overrides available for fine-grained control

### Prior Plan Reference

No prior plan.

## Goals & Non-Goals

**Goals**:
- Create `opencode.json` at project root with `edit: "allow"` and `external_directory: "ask"` permissions
- Deny destructive bash commands (`rm -rf`, `sudo`, `chmod 777`, `chmod -R`)
- Migrate `tts-notify.sh` temp paths from `/tmp/` to `specs/tmp/` across all copies
- Update `general-research-agent.md` to reference `specs/tmp/` instead of `/tmp/opencode/`
- Document the OpenCode permission configuration and dual-system architecture

**Non-Goals**:
- Modifying `.opencode/settings.json` (Claude Code config -- separate system)
- Changing extension settings fragments (Claude Code format)
- Adding per-agent permission overrides (future enhancement, not needed now)
- Modifying any existing `specs/tmp/` usage (already correct)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `opencode.json` conflicts with `.opencode/settings.json` | OpenCode reads both, unexpected behavior | Low | The two files use different formats (JSON object vs. flat arrays). Test by running OpenCode directly after creation |
| `git add *` or bulk operations corrupt `.git/` | Git history corruption | Low | The `edit: "allow"` applies to all in-root paths but git operations are manual. No risk unless agent runs destructive commands |
| `/tmp/opencode/` fallback still needed by agents | Session breakage | Low | Agent instructions already reference `/tmp/opencode/` in their system prompts. Migration to `specs/tmp/` in `general-research-agent.md` addresses this |
| `tts-notify.sh` copies fall out of sync | Hook behavior inconsistency across environments | Medium | Modify all 4 copies in one phase. Use grep to verify no remaining `/tmp/` references |
| `external_directory: "ask"` too strict for legitimate operations | Workflow friction | Low | If a legitimate use case arises, add specific path to `external_directory` allow list (documented pattern) |

## Implementation Phases

**Dependency Analysis**:
| Wave | Phases | Blocked by |
|------|--------|------------|
| 1 | 1, 2, 3 | -- |
| 2 | 4 | 1 |

Phases within the same wave can execute in parallel.

### Phase 1: Create opencode.json [NOT STARTED]

**Goal**: Create the primary OpenCode permission configuration file at the project root with auto-approval for workspace-internal edits and explicit denial of destructive bash commands.

**Tasks**:
- [ ] **Task 1.1**: Create `opencode.json` at repository root (`/home/benjamin/.config/nvim/opencode.json`) with schema reference, default agent, and permission block
- [ ] **Task 1.2**: Configure `permission.edit: "allow"` for auto-approved in-root writes
- [ ] **Task 1.3**: Configure `permission.external_directory` with `"*": "ask"` default and `"/tmp/opencode/**": "allow"` fallback
- [ ] **Task 1.4**: Configure `permission.bash` with `"*": "allow"` default and deny rules for `rm -rf *`, `sudo *`, `chmod 777 *`, `chmod -R *`

**Timing**: 0.5 hours

**Depends on**: none

**Files to create**:
- `opencode.json` - New OpenCode permission configuration file

**Verification**:
- File exists at project root: `ls -la opencode.json`
- Valid JSON: `jq empty opencode.json`
- Contains `$schema`, `default_agent`, and `permission` keys
- Contains `edit: "allow"`, `external_directory` object, `bash` object with deny rules

**Notes**: The research report provides the exact JSON template to use (see Recommendations, Priority 1).

---

### Phase 2: Migrate tts-notify.sh Temp Paths [NOT STARTED]

**Goal**: Replace all `/tmp/` path references in `tts-notify.sh` hook scripts with `specs/tmp/` paths, eliminating the last remaining dependency on external temp directories.

**Tasks**:
- [ ] **Task 2.1**: Update `LAST_NOTIFY_FILE` path from `/tmp/opencode-tts-last-notify` to `specs/tmp/opencode-tts-last-notify` in all 4 copies of `tts-notify.sh`
- [ ] **Task 2.2**: Update `LOG_FILE` path from `/tmp/opencode-tts-notify.log` to `specs/tmp/opencode-tts-notify.log` in all 4 copies
- [ ] **Task 2.3**: Update `TEMP_WAV` path from `/tmp/opencode-tts-$$.wav` to `specs/tmp/opencode-tts-$$.wav` in all 4 copies
- [ ] **Task 2.4**: Verify no remaining `/tmp/` references exist in any `tts-notify.sh` copy

**Timing**: 0.5 hours

**Depends on**: none

**Files to modify**:
- `.opencode/hooks/tts-notify.sh` - Change temp file paths
- `.opencode/extensions/core/hooks/tts-notify.sh` - Change temp file paths
- `.claude/hooks/tts-notify.sh` - Change temp file paths
- `.claude/extensions/core/hooks/tts-notify.sh` - Change temp file paths

**Verification**:
- No `/tmp/` references in: `grep -r '/tmp/' **/tts-notify.sh` (should produce no output)
- All 4 copies contain `specs/tmp/` paths: `grep -r 'specs/tmp/' **/tts-notify.sh` (should show 3 matches per file)
- Scripts remain syntactically valid bash (path substitutions only, no structural changes)

---

### Phase 3: Update Agent Instructions [NOT STARTED]

**Goal**: Update `general-research-agent.md` instruction text to reference `specs/tmp/` instead of `/tmp/opencode/`, aligning the documented temp directory convention with actual project practice.

**Tasks**:
- [ ] **Task 3.1**: Change "Use `/tmp/opencode` for temporary work outside the workspace" to "Use `specs/tmp/` for temporary work within the project" in all 4 copies of `general-research-agent.md`
- [ ] **Task 3.2**: Verify no remaining `/tmp/opencode` references exist in agent instructions

**Timing**: 0.25 hours

**Depends on**: none

**Files to modify**:
- `.opencode/extensions/core/agents/general-research-agent.md` - Update temp path instruction
- `.claude/extensions/core/agents/general-research-agent.md` - Update temp path instruction
- `.claude/agents/general-research-agent.md` - Update temp path instruction
- `.opencode/agent/subagents/general-research-agent.md` - Update temp path instruction

**Verification**:
- No `/tmp/opencode` references in: `grep -r '/tmp/opencode' **/general-research-agent.md` (should produce no output)
- All 4 copies contain updated instruction text referencing `specs/tmp/`

---

### Phase 4: Create Permission Documentation [NOT STARTED]

**Goal**: Create a documentation guide at `.opencode/docs/guides/opencode-permission-configuration.md` that explains the OpenCode permission system configuration, the dual-system architecture, and how to manage external directory access.

**Tasks**:
- [ ] **Task 4.1**: Create `.opencode/docs/guides/opencode-permission-configuration.md` with sections covering: dual-system architecture (Claude Code vs. OpenCode), `opencode.json` structure, `external_directory` behavior, bash safety rules, and how to add new allowed external paths
- [ ] **Task 4.2**: Include a reference to the existing `.opencode/docs/guides/permission-configuration.md` (Claude Code frontmatter format) for context on the Claude Code permission system
- [ ] **Task 4.3**: Document the `/tmp/opencode/` fallback pattern and when it should be used vs. `specs/tmp/`

**Timing**: 0.5 hours

**Depends on**: 1

**Files to create**:
- `.opencode/docs/guides/opencode-permission-configuration.md` - New documentation guide

**Verification**:
- File exists: `ls -la .opencode/docs/guides/opencode-permission-configuration.md`
- Contains sections on dual-system architecture, `opencode.json` structure, `external_directory`, bash rules
- References the existing `permission-configuration.md` guide
- Contains actionable instructions for adding new external paths

## Testing & Validation

- [ ] **opencode.json is valid JSON**: `jq empty opencode.json` exits cleanly (no parse errors)
- [ ] **tts-notify.sh has no /tmp/ references**: `grep -r '/tmp/' **/tts-notify.sh` produces no output
- [ ] **general-research-agent.md has no /tmp/opencode references**: `grep -r '/tmp/opencode' **/general-research-agent.md` produces no output
- [ ] **No duplicate `specs/tmp/` path errors**: Review all modified files for correct `specs/tmp/opencode-tts-*` paths (no double `specs/tmp/specs/tmp/`)
- [ ] **Documentation covers key concepts**: Dual-system architecture, external_directory behavior, how to add allowed external paths

## Artifacts & Outputs

- `opencode.json` - OpenCode permission configuration at project root
- `specs/548_research_opencode_permissions/plans/01_opencode-permissions-plan.md` - This plan (metadata: planned)
- `.opencode/docs/guides/opencode-permission-configuration.md` - Permission system documentation guide
- Modified: 4 copies of `.opencode/hooks/tts-notify.sh` and `.claude/hooks/tts-notify.sh` (temp paths updated)
- Modified: 4 copies of `general-research-agent.md` (temp directory instruction updated)

## Rollback/Contingency

If permission prompts increase or break workflows after deploying `opencode.json`:
1. Restore from git: `git checkout opencode.json` (if already committed) or `rm opencode.json` (removes the file, reverting to defaults)
2. If `specs/tmp/` migration for `tts-notify.sh` causes hook failures: restore `/tmp/` paths from git (`git checkout -- **/tts-notify.sh`)
3. If `specs/tmp/` paths don't exist at hook invocation time: the hook scripts already use `mkdir -p` for temp directories -- this handles the case gracefully
