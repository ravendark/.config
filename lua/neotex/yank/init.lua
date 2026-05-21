--- neotex.yank
--- Custom yank ring with non-blocking clipboard integration.
---
--- Replaces yanky.nvim to fix post-sleep Wayland clipboard hangs.
--- Uses vim.system() with timeout for all clipboard operations.
---
--- Features:
---   - Yank ring with configurable history (default 50)
---   - Non-blocking system clipboard sync via wl-paste/xclip
---   - Built-in yank highlighting via vim.hl.on_yank()
---   - Telescope picker for browsing history
---   - Post-sleep rendering recovery autocommands
---
--- Usage:
---   require("neotex.yank").setup({})

local M = {}

local ring = require("neotex.yank.ring")
local clipboard = require("neotex.yank.clipboard")
local highlight = require("neotex.yank.highlight")
local telescope = require("neotex.yank.telescope")
local recovery = require("neotex.yank.recovery")

local defaults = {
  ring = {
    max_size = 50,
  },
  clipboard = {
    timeout_ms = 2000,
    sync_on_focus = true,
  },
  highlight = {
    higroup = "IncSearch",
    timeout = 150,
    on_macro = false,
    on_visual = true,
  },
  recovery = {
    enabled = true,
  },
}

--- Setup the yank ring system.
--- @param opts table|nil User configuration (merged with defaults)
function M.setup(opts)
  local config = vim.tbl_deep_extend("force", defaults, opts or {})

  ring.setup(config.ring)
  clipboard.setup(config.clipboard)
  highlight.setup(config.highlight)

  local group = vim.api.nvim_create_augroup("NeoTexYank", { clear = true })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    pattern = "*",
    callback = function()
      local event = vim.v.event
      if event.operator == "d" and event.regname == "_" then
        return
      end

      local regcontents = table.concat(event.regcontents, "\n")

      ring.push({
        regcontents = regcontents,
        regtype = event.regtype,
      })

      clipboard.update_last(regcontents)
      highlight.on_yank()
    end,
    desc = "Yank: Capture to ring and highlight",
  })

  if config.clipboard.sync_on_focus then
    vim.api.nvim_create_autocmd("FocusGained", {
      group = group,
      pattern = "*",
      callback = function()
        clipboard.sync_to_ring(ring)
      end,
      desc = "Yank: Async clipboard sync on focus",
    })
  end

  if config.recovery.enabled then
    recovery.setup({ augroup = group })
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      ring.clear()
    end,
    desc = "Yank: Cleanup on exit",
  })

  M._ring = ring
  M._clipboard = clipboard
end

--- Open Telescope yank history picker.
function M.telescope_history()
  telescope.open(M._ring)
end

--- Clear yank history.
function M.clear_history()
  M._ring.clear()
  vim.notify("[yank] History cleared", vim.log.levels.INFO)
end

--- Get the ring module (for advanced usage).
--- @return table ring
function M.ring()
  return M._ring
end

return M
