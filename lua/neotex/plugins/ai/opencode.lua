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

    -- Cleanup stale opencode.json agents on startup (defense-in-depth)
    local ok_cleanup, cleanup_err = pcall(function()
      local ext_manager = require("neotex.plugins.ai.shared.extensions")
      local ext_config_mod = require("neotex.plugins.ai.shared.extensions.config")
      local project_dir = vim.fn.getcwd()
      local cfg = ext_config_mod.opencode(project_dir)
      local manager = ext_manager.create(cfg)
      manager.cleanup_stale_opencode_agents(project_dir)
    end)
    if not ok_cleanup then
      vim.schedule(function()
        vim.notify("Warning: opencode.json cleanup failed on startup: " .. tostring(cleanup_err), vim.log.levels.WARN)
      end)
    end

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
