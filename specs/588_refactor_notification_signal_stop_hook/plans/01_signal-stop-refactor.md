# Implementation Plan: Task #588

- **Task**: 588 - refactor_notification_signal_stop_hook
- **Status**: [PLANNED]
- **Effort**: 4 hours
- **Dependencies**: None
- **Research Inputs**: specs/588_refactor_notification_signal_stop_hook/reports/01_signal-stop-refactor.md
- **Artifacts**: plans/01_signal-stop-refactor.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false

## Overview

The notification system has three interlocking bugs: TTS from skill Stage 8a is unreliable because agents skip it, the Stop hook always overwrites lifecycle tab color with `needs_input`, and `update-task-status.sh` Phase 5 duplicates the wezterm call already made by `lifecycle-notify.sh`. This plan replaces the current multi-point dispatch with a signal-file + Stop hook pattern: `update-task-status.sh` writes a `.claude/tmp/lifecycle-signal` file as its last postflight action, and a new `claude-stop-notify.sh` Stop hook script atomically consumes that signal to dispatch both TTS and wezterm color in one reliable location. Stage 8a is removed from all four skill files, and the pattern is mirrored in the OpenCode tree.

### Research Integration

Key findings integrated from `reports/01_signal-stop-refactor.md`:
- Complete file inventory of all 7 tts-notify.sh copies and 4 wezterm-notify.sh variants
- Atomic `mv`-based consume pattern to prevent double-fire on concurrent Stop hook invocations
- Subagent detection pattern (check `agent_id` in stdin JSON) to suppress lifecycle on subagent stops
- OpenCode `wezterm-notify.sh` hardcodes `needs_input` and needs STATUS parameter added; OpenCode `tts-notify.sh` is already identical to the Claude Code version (has `--lifecycle` mode)
- Race condition analysis confirming signal-last-write ordering prevents stale signals

### Prior Plan Reference

No prior plan.

### Roadmap Alignment

No ROADMAP.md found.

### Literature Source Mapping

No literature source referenced.

## Goals & Non-Goals

**Goals**:
- Centralize all TTS and wezterm color dispatch into the Stop hook so both always fire reliably
- Remove agent-dependent Stage 8a blocks from four skill files
- Preserve correct lifecycle tab coloring (researched/planned/completed) across agent turns
- Support atomic signal consumption to prevent double-fire and race conditions
- Mirror all changes in the OpenCode tree for parity

**Non-Goals**:
- Modifying `wezterm.lua` (nix-managed, read-only, already handles all status values)
- Changing out-of-project tts-notify.sh copies (`~/.config/zed/`, `~/.config/.claude/`)
- Adding new status values or color mappings to the wezterm tab handler
- Redesigning the TTS pipeline or changing the piper model configuration

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Stop hook fires before signal file is written (timing gap) | H | M | Write signal as the LAST action in update-task-status.sh Phase 5, after all state updates |
| `.claude/tmp/` directory does not exist | M | H | Both write and read scripts use `mkdir -p .claude/tmp` before file operations |
| Subagent Stop events consume the lifecycle signal | H | H | Check stdin JSON for `agent_id` field; suppress lifecycle dispatch for subagents |
| Signal file accumulates if Stop hook crashes | L | L | File is consumed atomically; stale files are overwritten by next task status update |
| Extension copies drift from primary hooks | M | M | Create extension copies in same phase as primary; document sync requirement |
| OpenCode wezterm-notify.sh lacks STATUS parameter | M | M | Update OpenCode copy to accept optional status parameter (Phase 3) |

## Implementation Phases

**Dependency Analysis**:
| Wave | Phases | Blocked by |
|------|--------|------------|
| 1 | 1 | -- |
| 2 | 2, 3 | 1 |
| 3 | 4 | 2, 3 |

Phases within the same wave can execute in parallel.

### Phase 1: Create claude-stop-notify.sh and modify update-task-status.sh [NOT STARTED]

**Goal**: Establish the core signal-file mechanism: writing the signal in postflight and consuming it in the Stop hook.

**Tasks**:
- [ ] Create `.claude/tmp/` directory guard pattern (both scripts use `mkdir -p`)
- [ ] Modify `.claude/scripts/update-task-status.sh` Phase 5: remove the `wezterm-notify.sh "$STATE_STATUS"` call (lines 363-370) and replace with signal file write (`echo "$STATE_STATUS" > ".claude/tmp/lifecycle-signal"`) as the LAST action in the postflight block
- [ ] Create `.claude/hooks/claude-stop-notify.sh` with:
  - Subagent detection (read stdin JSON, check `agent_id` field, exit early for subagents)
  - Atomic signal consume via `mv .claude/tmp/lifecycle-signal .claude/tmp/lifecycle-signal.consumed`
  - On signal present: read status, delete consumed file, call `wezterm-notify.sh "$STATUS"` and `tts-notify.sh --lifecycle "$STATUS"`
  - On no signal: call `wezterm-notify.sh` (needs_input default) and `tts-notify.sh` (interactive "Tab N")
  - Same error handling patterns as existing hook scripts (set -uo pipefail, exit_success helper)
- [ ] Make `claude-stop-notify.sh` executable (`chmod +x`)
- [ ] Update `.claude/settings.json` Stop hook: replace `bash .claude/hooks/wezterm-notify.sh 2>/dev/null || echo '{}'` with `bash .claude/hooks/claude-stop-notify.sh 2>/dev/null || echo '{}'`

**Timing**: 1.5 hours

**Depends on**: none

**Files to modify**:
- `.claude/scripts/update-task-status.sh` - Replace Phase 5 wezterm call with signal file write
- `.claude/hooks/claude-stop-notify.sh` - NEW: unified Stop hook dispatcher
- `.claude/settings.json` - Replace wezterm-notify.sh with claude-stop-notify.sh in Stop hook

**Verification**:
- `claude-stop-notify.sh` exists and is executable
- `update-task-status.sh` no longer calls `wezterm-notify.sh` directly in Phase 5
- `settings.json` Stop hook references `claude-stop-notify.sh` instead of `wezterm-notify.sh`
- Manual test: run `bash .claude/scripts/update-task-status.sh` in postflight mode and confirm `.claude/tmp/lifecycle-signal` is created with correct status value

---

### Phase 2: Remove Stage 8a from skills and stub lifecycle-notify.sh [NOT STARTED]

**Goal**: Remove all agent-side notification dispatch (Stage 8a blocks) and convert lifecycle-notify.sh to a backward-compatible no-op stub.

**Tasks**:
- [ ] Remove Stage 8a block from `.claude/skills/skill-researcher/SKILL.md` (lines ~474-488): remove heading, code fence, commentary, and trailing `---` divider
- [ ] Remove Stage 8a block from `.claude/skills/skill-planner/SKILL.md` (lines ~368-382): same structure
- [ ] Remove Stage 8a block from `.claude/skills/skill-implementer/SKILL.md` (lines ~535-549): same structure
- [ ] Remove Stage 8a block from `.claude/skills/skill-reviser/SKILL.md` (lines ~373-387): same structure
- [ ] Verify that the stage numbering after removal is consistent (Stage 8b or Stage 9 follows Stage 8 naturally)
- [ ] Replace `.claude/scripts/lifecycle-notify.sh` contents with a no-op stub: deprecation comment referencing task 588 and `exit 0`

**Timing**: 1 hour

**Depends on**: 1

**Files to modify**:
- `.claude/skills/skill-researcher/SKILL.md` - Remove Stage 8a block
- `.claude/skills/skill-planner/SKILL.md` - Remove Stage 8a block
- `.claude/skills/skill-implementer/SKILL.md` - Remove Stage 8a block
- `.claude/skills/skill-reviser/SKILL.md` - Remove Stage 8a block
- `.claude/scripts/lifecycle-notify.sh` - Convert to no-op stub

**Verification**:
- `grep -r "Stage 8a" .claude/skills/` returns no results
- `lifecycle-notify.sh` is a no-op (only comment + `exit 0`)
- No remaining references to `lifecycle-notify.sh` in active code paths (old skill calls use `if [ -f ... ]` guard and will silently no-op since the file still exists)

---

### Phase 3: OpenCode parity and extension copies [NOT STARTED]

**Goal**: Mirror all changes in the OpenCode tree and create extension copies for both Claude Code and OpenCode.

**Tasks**:
- [ ] Update `.opencode/hooks/wezterm-notify.sh` to accept an optional STATUS parameter (default `needs_input`), matching `.claude/hooks/wezterm-notify.sh` behavior: parse `$1` as status, use it for base64 encoding instead of hardcoded `needs_input`
- [ ] Create `.opencode/hooks/claude-stop-notify.sh` as OpenCode variant of the unified Stop hook (adapted paths: `.opencode/tmp/` signal file, `.opencode/hooks/` script references)
- [ ] Make `.opencode/hooks/claude-stop-notify.sh` executable
- [ ] Update `.opencode/settings.json` Stop hook: replace `bash .opencode/hooks/wezterm-notify.sh` with `bash .opencode/hooks/claude-stop-notify.sh`
- [ ] Create `.claude/extensions/core/hooks/claude-stop-notify.sh` as copy of `.claude/hooks/claude-stop-notify.sh`
- [ ] Update `.claude/extensions/core/root-files/settings.json` Stop hook: replace `wezterm-notify.sh` with `claude-stop-notify.sh`
- [ ] Create `.opencode/extensions/core/hooks/claude-stop-notify.sh` as copy of `.opencode/hooks/claude-stop-notify.sh`
- [ ] Update `.opencode/extensions/core/hooks/wezterm-notify.sh` to match the updated `.opencode/hooks/wezterm-notify.sh` (accept STATUS parameter)

**Timing**: 1 hour

**Depends on**: 1

**Files to modify**:
- `.opencode/hooks/wezterm-notify.sh` - Add optional STATUS parameter
- `.opencode/hooks/claude-stop-notify.sh` - NEW: OpenCode unified Stop hook
- `.opencode/settings.json` - Replace wezterm-notify.sh in Stop hook
- `.claude/extensions/core/hooks/claude-stop-notify.sh` - NEW: extension copy
- `.claude/extensions/core/root-files/settings.json` - Update Stop hook reference
- `.opencode/extensions/core/hooks/claude-stop-notify.sh` - NEW: OpenCode extension copy
- `.opencode/extensions/core/hooks/wezterm-notify.sh` - Add STATUS parameter

**Verification**:
- All four `settings.json` files reference `claude-stop-notify.sh` in Stop hook (not `wezterm-notify.sh`)
- `diff .claude/hooks/claude-stop-notify.sh .claude/extensions/core/hooks/claude-stop-notify.sh` shows only path differences
- `.opencode/hooks/wezterm-notify.sh` accepts a status parameter and no longer hardcodes `needs_input`
- All new scripts are executable

---

### Phase 4: Integration testing and documentation [NOT STARTED]

**Goal**: Verify the complete signal-file pipeline end-to-end and clean up any loose ends.

**Tasks**:
- [ ] End-to-end test: simulate a postflight cycle by calling `update-task-status.sh` with a test task in postflight mode, confirm signal file is created, then run `claude-stop-notify.sh` and confirm signal is consumed and scripts are called with correct arguments
- [ ] Verify subagent suppression: pipe JSON with `agent_id` field to `claude-stop-notify.sh` stdin and confirm it exits without consuming signal
- [ ] Verify no-signal path: run `claude-stop-notify.sh` without a signal file and confirm it dispatches `needs_input` default behavior
- [ ] Verify backward compatibility: confirm `lifecycle-notify.sh` stub exits 0 silently
- [ ] Check for any remaining references to the old wezterm-notify.sh Stop hook pattern in documentation or scripts that need updating
- [ ] Ensure `.claude/tmp/` and `.opencode/tmp/` are in `.gitignore` (signal files should not be committed)

**Timing**: 30 minutes

**Depends on**: 2, 3

**Files to modify**:
- `.gitignore` - Add `.claude/tmp/` and `.opencode/tmp/` if not already present

**Verification**:
- Complete postflight-to-stop-hook cycle produces correct TTS and wezterm color for each lifecycle status (researched, planned, completed)
- Subagent stops do not trigger lifecycle announcements
- No signal file means `needs_input` default behavior
- `git status` shows no untracked files in `.claude/tmp/` or `.opencode/tmp/`

---

## Testing & Validation

- [ ] Signal file write: `update-task-status.sh` postflight creates `.claude/tmp/lifecycle-signal` with correct status value
- [ ] Signal file consume: `claude-stop-notify.sh` reads and atomically deletes the signal file via `mv` rename pattern
- [ ] Correct dispatch: TTS speaks "Tab N {status}" and wezterm tab color matches lifecycle state
- [ ] No-signal path: Stop hook without signal file defaults to `needs_input` + "Tab N"
- [ ] Subagent suppression: `claude-stop-notify.sh` exits early when stdin contains `agent_id`
- [ ] Backward compatibility: `lifecycle-notify.sh` exits 0 without side effects
- [ ] No Stage 8a: `grep -r "Stage 8a" .claude/skills/` returns empty
- [ ] Settings parity: all four settings.json files reference `claude-stop-notify.sh`
- [ ] OpenCode wezterm-notify.sh accepts STATUS parameter

## Artifacts & Outputs

- `specs/588_refactor_notification_signal_stop_hook/plans/01_signal-stop-refactor.md` (this plan)
- `.claude/hooks/claude-stop-notify.sh` (new unified Stop hook)
- `.opencode/hooks/claude-stop-notify.sh` (new OpenCode variant)
- `.claude/extensions/core/hooks/claude-stop-notify.sh` (extension copy)
- `.opencode/extensions/core/hooks/claude-stop-notify.sh` (extension copy)
- `.claude/scripts/lifecycle-notify.sh` (converted to no-op stub)

## Rollback/Contingency

If the signal-file pattern causes unexpected issues:
1. Restore `wezterm-notify.sh` in all four `settings.json` Stop hook entries
2. Restore Phase 5 wezterm call in `update-task-status.sh` (revert to direct `wezterm-notify.sh "$STATE_STATUS"` call)
3. Restore Stage 8a blocks in the four skill files (available from git history)
4. Restore `lifecycle-notify.sh` from git history
5. Delete `claude-stop-notify.sh` from all locations

All original files are tracked in git, so `git checkout` of affected files provides immediate rollback. The signal file (`.claude/tmp/lifecycle-signal`) can simply be deleted.
