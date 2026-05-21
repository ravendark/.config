--- neotex.yank.telescope
--- Telescope picker for browsing yank history.
--- Adapted from the user's existing custom YankyTelescopeHistory picker.

local M = {}

--- Open the yank history in Telescope.
--- @param ring table The ring module (neotex.yank.ring)
function M.open(ring)
  local ok, _ = pcall(require, "telescope")
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
  if #entries == 0 then
    vim.notify("[yank] No entries in yank history", vim.log.levels.INFO)
    return
  end

  local previewer = previewers.new_buffer_previewer({
    title = "Yanked Text",
    define_preview = function(self, entry)
      local lines = vim.split(entry.value.regcontents, "\n")
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, lines)
      if entry.value.filetype then
        vim.bo[self.state.bufnr].filetype = entry.value.filetype
      end
    end,
  })

  local make_entry = function(item)
    local display = item.regcontents:gsub("\n", "\\n")
    if #display > 80 then
      display = display:sub(1, 77) .. "..."
    end
    return {
      value = item,
      ordinal = item.regcontents,
      display = display,
    }
  end

  pickers.new({}, {
    prompt_title = "Yank History",
    finder = finders.new_table({
      results = entries,
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewer,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          return
        end

        vim.schedule(function()
          vim.fn.setreg("+", selection.value.regcontents, selection.value.regtype)
          vim.cmd('normal! "+p')
        end)
      end)
      return true
    end,
  }):find()
end

return M
