local M = {}

function M.open(ring)
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("[yank] Telescope not available", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local entries = ring.all()

  local previewer = previewers.new_buffer_previewer({
    title = "Yanked Text",
    define_preview = function(self, entry)
      local lines = vim.split(entry.value.regcontents, "\n")
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, lines)
      if entry.value.filetype and entry.value.filetype ~= "" then
        vim.bo[self.state.bufnr].filetype = entry.value.filetype
      end
    end,
  })

  local make_entry = function(entry)
    return {
      value = entry,
      ordinal = entry.regcontents,
      display = entry.regcontents:gsub("\n", "\\n"):sub(1, 80),
    }
  end

  pickers.new({}, {
    prompt_title = "Yank History (C-k: clear)",
    finder = finders.new_table({
      results = entries,
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewer,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          return
        end
        vim.schedule(function()
          vim.fn.setreg('"', selection.value.regcontents, selection.value.regtype)
          vim.cmd("normal! p")
        end)
      end)
      map("i", "<C-k>", function()
        actions.close(prompt_bufnr)
        ring.clear()
        vim.notify("[yank] History cleared", vim.log.levels.INFO)
      end)
      return true
    end,
  }):find()
end

return M
