-- neotex.plugins.ai.opencode
-- OpenCode.nvim plugin configuration using NickvanDyke variant
-- Provides embedded TUI experience for opencode CLI with powerful context placeholders

return {
  "NickvanDyke/opencode.nvim",
  event = "VeryLazy",
  dependencies = {
    {
      "folke/snacks.nvim",
      opts = {
        input = {},
        picker = {},
        terminal = {},
      },
    },
  },
  init = function()
    -- Only non-function options can go in vim.g (Neovim serializes vim.g to msgpack;
    -- functions are dropped silently). Server functions are set in config() below.
    vim.g.opencode_opts = {
      events = {
        enabled = true,
        reload = true,
        permissions = {
          enabled = false, -- Disable permission UI to prevent prompts
        },
      },
    }

    -- Enable autoread for buffer reloading
    vim.o.autoread = true
  end,
  config = function()
    -- Set server functions directly on opts (bypasses vim.g serialization limitation)
    local opts = require("opencode.config").opts
    local opencode_win_opts = {
      win = {
        position = "right",
        width = 0.40, -- 40% window width per user standards
        enter = true, -- Enter terminal on toggle
        on_win = function(win)
          -- Attach opencode keymaps (<C-u>/<C-d>/gg/G/<Esc>) and process cleanup
          require("opencode.terminal").setup(win.win)
        end,
      },
    }
    opts.server = {
      start = function()
        require("snacks.terminal").open("opencode --port", opencode_win_opts)
      end,
      stop = function()
        local term = require("snacks.terminal").get("opencode --port", opencode_win_opts)
        if term then term:close() end
      end,
      toggle = function()
        require("snacks.terminal").toggle("opencode --port", opencode_win_opts)
      end,
    }

    -- Register OpencodeCommands command (main artifact picker)
    vim.api.nvim_create_user_command("OpencodeCommands", function()
      require("neotex.plugins.ai.opencode.commands.picker").show_commands_picker()
    end, { desc = "Browse OpenCode commands, skills, agents, and extensions" })

    -- Register OpencodeExtensions command (extension management)
    vim.api.nvim_create_user_command("OpencodeExtensions", function()
      require("neotex.plugins.ai.opencode.extensions.picker").show()
    end, { desc = "Manage OpenCode extensions" })
  end,
  keys = {},
}
