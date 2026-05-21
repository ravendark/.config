--- neotex.yank.recovery
--- FocusGained / VimResume recovery autocommands.
--- Fixes rendering corruption after system sleep by forcing
--- a full terminal + treesitter refresh.

local M = {}

--- Force a full display recovery.
--- Safe to call at any time; no-ops gracefully if nothing needs recovery.
function M.recover()
  vim.cmd("mode")
  vim.cmd("redraw!")

  local bufnr = vim.api.nvim_get_current_buf()
  if vim.treesitter.get_parser then
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if ok and parser then
      parser:invalidate(true)
      pcall(function() parser:parse() end)
    end
  end

  vim.cmd("doautocmd CursorMoved")
end

--- @param opts { augroup: integer }
function M.setup(opts)
  local group = opts.augroup

  vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
    group = group,
    pattern = "*",
    callback = function()
      M.recover()
    end,
    desc = "Yank: Recover display after sleep/focus",
  })
end

return M
