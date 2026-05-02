# Core Extension (OpenCode)

## Overview

The core extension provides the base agent system infrastructure for OpenCode. It contains
all fundamental commands, agents, rules, skills, scripts, hooks, context, documentation, and
templates that power the task management and agent orchestration workflow.

## Purpose

This extension packages the core agent system files for OpenCode. It is the foundational
layer that all other OpenCode extensions build upon, providing the same capabilities as
the `.claude/extensions/core/` but adapted for the OpenCode extension system.

## What This Extension Provides

| Category | Count | Description |
|----------|-------|-------------|
| agents | 7 | Research, implementation, planning, meta, review, revision, spawn agents |
| commands | 15 | `/task`, `/research`, `/plan`, `/implement`, `/todo`, `/meta`, and more |
| rules | 7 | Auto-applied rules for state, git, artifacts, workflows, and error handling |
| skills | 17 | Skill definitions including team mode, orchestration, and utility skills |
| scripts | 27 | Utility scripts for validation, hooks, memory, and extension management |
| hooks | 11 | Session logging, memory nudging, WezTerm notifications, validation hooks |
| context | 18 dirs | Architecture, patterns, guides, schemas, workflows, and reference material |
| docs | 7 dirs | Standards documentation, architecture guides, and references |
| templates | 3 | Extension README template and settings.json template |
| systemd | 2 | Refresh service and timer units |

## Key Capabilities

- **Task Management**: Full lifecycle from creation through research, planning, implementation,
  and archival via `/todo`
- **Agent Orchestration**: Routing, delegation, and team mode for parallel execution
- **State Management**: Atomic synchronization of TODO.md and state.json
- **Memory System**: Auto-retrieval hooks and distillation support
- **Extension Infrastructure**: Scripts to install, validate, and manage other extensions

## Usage Notes

- This extension is the foundational layer for all other OpenCode extensions
- All core commands (e.g., `/implement`, `/research`) are defined here
- Context files are auto-loaded by agents via the context index
- Scripts are callable from hooks and other scripts using the extension-relative path
- The `context/reference/team-wave-helpers.md` file provides reusable wave patterns for team skills

## Dependencies

None. This is the foundational layer all other extensions build upon.

## Related Files

- `.opencode/AGENTS.md` - Agent system configuration and quick reference
- `.opencode/context/index.json` - Context discovery index
- `.opencode/extensions.json` - Extension registry
