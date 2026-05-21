--- neotex.yank.highlight
--- Yank highlighting using Neovim's built-in vim.hl.on_yank().

local M = {}

M._opts = {
  higroup = "IncSearch",
  timeout = 150,
  on_macro = false,
  on_visual = true,
}

--- Configure highlight options.
--- @param opts { higroup?: string, timeout?: integer, on_macro?: boolean, on_visual?: boolean }
function M.setup(opts)
  M._opts = vim.tbl_extend("force", M._opts, opts or {})
end

--- Trigger yank highlighting. Call from TextYankPost autocommand.
function M.on_yank()
  vim.hl.on_yank(M._opts)
end

return M
