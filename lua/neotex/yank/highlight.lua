local M = {}

local _config = {
  higroup = "IncSearch",
  timeout = 150,
  on_macro = false,
  on_visual = true,
}

function M.setup(opts)
  _config = vim.tbl_deep_extend("force", _config, opts or {})
end

function M.on_yank()
  if not _config.on_macro and vim.fn.reg_executing() ~= "" then
    return
  end
  vim.hl.on_yank({
    higroup = _config.higroup,
    timeout = _config.timeout,
    on_visual = _config.on_visual,
  })
end

return M
