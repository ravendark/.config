# opencode.json Lifecycle Reference

- **Type**: Reference
- **Scope**: OpenCode extension system
- **Last Updated**: 2026-05-07
- **Related**: `specs/541_design_opencode_json_agent_registration/designs/01_agent-registration-design-spec.md`

## Overview

This document describes the full lifecycle of `opencode.json` from template installation through extension registration to cleanup and unload. It explains the managed/unmanaged distinction and how it governs sync behavior.

## Lifecycle Stages

### Stage 1: Template Installation

**Trigger**: First time the OpenCode picker is opened in a project without `opencode.json`

**Flow**:
1. `needs_base_install()` checks if `opencode.json` exists
2. If missing, `install_base_opencode_json()` copies the global template to the project root
3. Creates `.opencode.json.managed` sidecar marker
4. Returns `"Installed base opencode.json"`

**Code**: `lua/neotex/plugins/ai/opencode/core/init.lua` lines 65-126

### Stage 2: Extension Load (Agent Registration)

**Trigger**: User selects an extension in the `<leader>ao` picker and confirms load

**Flow**:
1. `manager.load()` reads the extension manifest
2. `process_merge_targets()` checks for `merge_targets.opencode_json`
3. `merge_opencode_agents()` reads the extension's `opencode-agents.json` fragment
4. Validates all `{file:...}` references exist
5. Adds each agent key to `opencode.json` if not already present
6. Tracks added keys in `merged_sections.opencode_json`
7. `state_mod.mark_loaded()` persists `merged_sections` to `extensions.json`

**Code**: `lua/neotex/plugins/ai/shared/extensions/init.lua` lines 122-146

### Stage 3: Sync Operation

**Trigger**: User runs `<leader>sp` (sync picker) and selects "Sync all"

**Flow**:
1. `load_all_globally()` scans global artifacts
2. For `opencode.json`, determines action based on managed status:
   - **Managed**: action = "replace" (overwrites with base template)
   - **Unmanaged**: action = "skip" (preserves user config)
3. If action is "replace", copies base template to project root
4. `reinject_loaded_extensions()` re-merges agents from all loaded extensions
5. `install_base_opencode_json()` runs via `on_load_all` callback (no-op if managed)

**Transient State Window**: Between steps 3 and 4, `opencode.json` temporarily lacks extension agents. This window is bounded to Lua execution time (Neovim is single-threaded).

**Code**: `lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` lines 869-907

### Stage 4: Cleanup

**Trigger**: Neovim startup, post-load, or post-unload

**Flow**:
1. `cleanup_stale_opencode_agents()` reads `opencode.json`
2. Scans each agent's `{file:...}` prompt reference
3. If the referenced file is missing, removes the agent entry
4. Writes updated `opencode.json`
5. Notifies user of removed agents

**Code**: `lua/neotex/plugins/ai/shared/extensions/init.lua` lines 834-877

### Stage 5: Extension Unload (Agent Deregistration)

**Trigger**: User selects an extension in the `<leader>ao` picker and confirms unload

**Flow**:
1. `manager.unload()` reads `extensions.json` for the extension's `merged_sections`
2. `reverse_merge_targets()` checks for `merged_sections.opencode_json`
3. `unmerge_opencode_agents()` removes tracked keys from `opencode.json`
4. `state_mod.mark_unloaded()` removes the extension from `extensions.json`

**Orphaning Edge Case**: If Extension A and B both define agent `"grant"`, and A loaded first, B's agent was skipped. When A is unloaded, `"grant"` is removed even though B is still loaded. B's agent remains missing until B is reloaded.

**Code**: `lua/neotex/plugins/ai/shared/extensions/init.lua` lines 150-186

## State Diagram

```
[No opencode.json]
       |
       v
[Template Install] --managed--> [Managed opencode.json]
       |                              |
       |--unmanaged--> [User opencode.json] (skip sync)
       |
[Extension Load] --> [Agents Merged] --> [extensions.json updated]
       |
[Sync All] --> [Replace managed] --> [Re-inject agents] --> [Managed opencode.json]
       |
[Cleanup] --> [Stale agents removed] --> [Clean opencode.json]
       |
[Extension Unload] --> [Tracked agents removed] --> [extensions.json updated]
```

## Managed vs Unmanaged

### Managed File

- Has `.opencode.json.managed` sidecar marker
- Created by template installation or sync
- Can be overwritten by sync-all
- Subject to automatic cleanup
- Extension agents are merged into it

### Unmanaged File

- No `.opencode.json.managed` sidecar marker
- Created manually by the user or imported from another project
- Never overwritten by sync
- Cleanup still runs but only warns about stale entries
- Extension agents are still merged into it

### Converting Between States

| From | To | Method |
|------|-----|--------|
| Unmanaged | Managed | Run sync-all or call `install_base_opencode_json()` (backs up to `.user-backup`) |
| Managed | Unmanaged | Delete `.opencode.json.managed` file manually |

### Sidecar Files

```
opencode.json              # The actual config file
opencode.json.managed      # Marker file: "managed-by: neotex-extensions\n"
opencode.json.user-backup  # Backup of previous unmanaged config
```

## User Customization Boundaries

### Allowed on Both Managed and Unmanaged

- Adding new agents manually (they persist across sync)
- Editing agent descriptions, tools, or prompts
- Removing agents (cleanup will not restore them)

### Preserved on Unmanaged Only

- Full file structure (agents, settings, metadata)
- Custom agent definitions
- Non-standard fields

### Reset on Managed During Sync-All

- File is replaced with base template
- Only extension agents and manual additions are re-merged
- Custom structures may be lost

## Best Practices

1. **For automatic management**: Let the system manage `opencode.json` (managed mode). Use sync-all to keep it updated.
2. **For manual control**: Remove `.managed` sidecar to make the file unmanaged. Sync will skip it.
3. **For custom agents in managed mode**: Add them directly to `opencode.json`. They will persist across sync because the merge pattern only adds missing keys.
4. **Before uninstalling extensions**: Unload extensions via the picker so their agents are properly unmerged.

## References

- Design spec: `specs/541_design_opencode_json_agent_registration/designs/01_agent-registration-design-spec.md`
- Base installer: `lua/neotex/plugins/ai/opencode/core/init.lua`
- Merge implementation: `lua/neotex/plugins/ai/shared/extensions/merge.lua`
- Sync implementation: `lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`
- Extension manager: `lua/neotex/plugins/ai/shared/extensions/init.lua`
