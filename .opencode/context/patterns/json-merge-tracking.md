# JSON Merge Tracking Pattern

- **Type**: Pattern
- **Scope**: OpenCode extension system
- **Last Updated**: 2026-05-07
- **Related**: `specs/541_design_opencode_json_agent_registration/designs/01_agent-registration-design-spec.md`

## Overview

The JSON merge tracking pattern enables idempotent, reversible merging of JSON fragments into target files. It is used by the OpenCode extension system to register agents in `opencode.json`, and is reusable for other JSON merge targets.

## Problem

When multiple extensions contribute keys to a shared JSON file (e.g., `opencode.json`), we need to:

1. Add extension-specific keys without overwriting existing keys
2. Remove extension-specific keys when the extension is unloaded
3. Preserve user-added keys or keys from other extensions

## Solution: Key-Based Tracking

The pattern uses a `keys` array to track which keys were added by a specific merge operation. This tracking data is stored in extension state (`extensions.json`) and used during unmerge.

### Data Structures

**Tracking data** (stored in `extensions.json`):
```lua
{
  keys = {"agent1", "agent2", "agent3"}
}
```

**Extension state entry**:
```json
{
  "name": "core",
  "loaded": true,
  "merged_sections": {
    "opencode_json": {
      "keys": ["code-reviewer", "general-implementation", "general-research"]
    }
  }
}
```

### Pseudocode: Merge

```lua
function merge(target_path, fragment, project_dir)
  -- Validate fragment
  valid, err = validate(fragment, project_dir)
  if not valid then return false, {error = err} end

  -- Read or create target
  target = read_json(target_path) or {}
  if not target.agent then target.agent = {} end

  -- Track added keys
  added_keys = {}

  -- Add each key if it doesn't exist
  for key, value in pairs(fragment.agent) do
    if target.agent[key] == nil then
      target.agent[key] = value
      table.insert(added_keys, key)
    else
      -- Conflict: key already exists (see Decision 1 in design spec)
      -- TODO: emit warning if owned by different extension
    end
  end

  -- Write updated target
  write_json(target_path, target)

  -- Return tracking data for unmerge
  return true, {keys = added_keys}
end
```

### Pseudocode: Unmerge

```lua
function unmerge(target_path, tracked)
  if not tracked or not tracked.keys then return true end

  target = read_json(target_path) or {}
  if not target.agent then return true end

  -- Remove only tracked keys
  for _, key in ipairs(tracked.keys) do
    target.agent[key] = nil
  end

  write_json(target_path, target)
  return true
end
```

### Key Properties

| Property | Description |
|----------|-------------|
| **Idempotent merge** | Running merge twice with the same fragment adds keys only once (second run finds keys already exist) |
| **Idempotent unmerge** | Running unmerge twice is safe (tracked keys are already removed) |
| **Non-destructive** | Unmerge only removes keys that were added by the corresponding merge; user keys and other extension keys are preserved |
| **Conflict-safe** | If two extensions define the same key, the first wins; the second's key is not tracked, so unmerge of the first does not affect the second's state |

## Real Implementation

The actual implementation is in `lua/neotex/plugins/ai/shared/extensions/merge.lua`:

- `merge_opencode_agents()` (lines 699-746): Merges agent definitions
- `unmerge_opencode_agents()` (lines 748-778): Removes tracked agent definitions
- `validate_opencode_fragment()` (lines 668-689): Validates `{file:...}` references

State tracking is in `lua/neotex/plugins/ai/shared/extensions/state.lua` (lines 122-133, 189-198).

## Reusability

This pattern can be applied to any JSON file that receives additive, reversible contributions:

- `settings.json` for extension-specific settings
- `package.json` for dependency injection
- Custom configuration files with shared namespaces

To reuse the pattern for a new merge target:

1. Define a `merge_target_key` in the extension config (e.g., `"my_json"`)
2. Implement `merge_my_json(target_path, fragment)` following the pseudocode above
3. Implement `unmerge_my_json(target_path, tracked)` following the pseudocode above
4. Register the merge target in `manifest.json`:
   ```json
   "merge_targets": {
     "my_json": {
       "source": "my-fragment.json",
       "target": "my-config.json"
     }
   }
   ```
5. Update `process_merge_targets()` in `init.lua` to handle the new key

## References

- Design spec: `specs/541_design_opencode_json_agent_registration/designs/01_agent-registration-design-spec.md`
- Merge implementation: `lua/neotex/plugins/ai/shared/extensions/merge.lua`
- State tracking: `lua/neotex/plugins/ai/shared/extensions/state.lua`
- Extension manager: `lua/neotex/plugins/ai/shared/extensions/init.lua`
