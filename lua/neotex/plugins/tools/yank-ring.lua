return {
  dir = vim.fn.stdpath("config") .. "/lua/neotex/yank",
  lazy = true,
  event = "VeryLazy",
  dependencies = {
    { "nvim-telescope/telescope.nvim", lazy = true },
  },
  config = function()
    local yank = require("neotex.yank")
    yank.setup({
      ring = { max_size = 50 },
      highlight = { higroup = "IncSearch", timeout = 150 },
    })
    _G.YankyTelescopeHistory = function()
      yank.telescope_history()
    end
  end,
}
