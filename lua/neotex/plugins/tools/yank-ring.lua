-----------------------------------------------------
-- Custom Yank Ring: Non-blocking Clipboard Integration
--
-- Replaces yanky.nvim to fix post-sleep Wayland clipboard hangs.
-- Uses vim.system() with timeout for all clipboard reads.
--
-- Features:
-- - Yank ring with configurable history (50 entries)
-- - Non-blocking system clipboard sync via wl-paste
-- - Built-in yank highlighting via vim.hl.on_yank()
-- - Telescope picker for browsing history
-- - Post-sleep rendering recovery autocommands
-----------------------------------------------------

return {
  dir = vim.fn.stdpath("config") .. "/lua/neotex/yank",
  name = "neotex-yank-ring",
  lazy = true,
  event = { "TextYankPost" },
  keys = {
    { "y", mode = { "n", "x" }, desc = "Yank text" },
    { "p", mode = "n", desc = "Put after cursor" },
    { "P", mode = "n", desc = "Put before cursor" },
    { "gp", mode = "n", desc = "Put after and leave cursor after" },
    { "gP", mode = "n", desc = "Put before and leave cursor after" },
  },
  dependencies = {
    { "nvim-telescope/telescope.nvim", lazy = true },
  },
  config = function()
    local yank = require("neotex.yank")

    yank.setup({
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
      },
      recovery = {
        enabled = true,
      },
    })

    _G.YankTelescopeHistory = function()
      yank.telescope_history()
    end
  end,
}
