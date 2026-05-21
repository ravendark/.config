local M = {}

local ring = require("neotex.yank.ring")
local highlight = require("neotex.yank.highlight")
local telescope = require("neotex.yank.telescope")

local defaults = {
  ring = {
    max_size = 50,
  },
  highlight = {
    higroup = "IncSearch",
    timeout = 150,
    on_macro = false,
    on_visual = true,
  },
}

function M.setup(opts)
  local config = vim.tbl_deep_extend("force", defaults, opts or {})

  ring.setup(config.ring)
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
        filetype = vim.bo.filetype,
        timestamp = vim.uv.now(),
      })
      highlight.on_yank()
    end,
    desc = "Yank: capture to ring and highlight",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      ring.clear()
    end,
    desc = "Yank: cleanup on exit",
  })

  M._ring = ring
end

function M.telescope_history()
  if not M._ring then
    vim.notify("[yank] Module not initialized", vim.log.levels.WARN)
    return
  end
  telescope.open(M._ring)
end

function M.clear_history()
  if M._ring then
    M._ring.clear()
  end
  vim.notify("[yank] History cleared", vim.log.levels.INFO)
end

return M
