-- neotex.plugins.ai.shared.picker.ai-tool-picker
-- Unified two-stage AI tool picker with session management
-- Stage 1: vim.ui.select for Claude Code vs OpenCode
-- Stage 2: per-tool session picker (Telescope dropdown for OpenCode, delegate for Claude)

local M = {}

local data_dir = vim.fn.stdpath("data") .. "/neotex-ai"
local tool_prefs_file = data_dir .. "/tool-prefs.json"
local opencode_session_file = data_dir .. "/opencode-last-session.json"

-- Track initialization
M._initialized = false

-- In-memory cache of tool preferences
local tool_prefs = {
  last_tool = nil, -- "claude" | "opencode" | nil
  last_updated = nil,
}

-----------------------------------------------------------------------
-- DATA DIRECTORY & ATOMIC WRITE HELPERS
-----------------------------------------------------------------------

local function ensure_data_dir()
  if vim.fn.isdirectory(data_dir) == 0 then
    vim.fn.mkdir(data_dir, "p")
  end
end

local function atomic_write(filepath, data)
  local encoded = vim.fn.json_encode(data)
  local tmp = filepath .. ".tmp"
  local f = io.open(tmp, "w")
  if not f then
    return false
  end
  f:write(encoded)
  f:close()
  local ok = os.rename(tmp, filepath)
  return ok ~= nil
end

local function atomic_read(filepath)
  local f = io.open(filepath, "r")
  if not f then
    return nil
  end
  local content = f:read("*all")
  f:close()
  if content == "" then
    return nil
  end
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then
    return nil
  end
  return data
end

-----------------------------------------------------------------------
-- TOOL PREFERENCE PERSISTENCE
-----------------------------------------------------------------------

local function load_tool_prefs()
  local data = atomic_read(tool_prefs_file)
  if data and (data.last_tool == "claude" or data.last_tool == "opencode") then
    tool_prefs.last_tool = data.last_tool
    tool_prefs.last_updated = data.last_updated
  end
end

local function save_tool_prefs(tool)
  tool_prefs.last_tool = tool
  tool_prefs.last_updated = os.time()
  ensure_data_dir()
  atomic_write(tool_prefs_file, tool_prefs)
end

-----------------------------------------------------------------------
-- ACTIVE TERMINAL DETECTION
-----------------------------------------------------------------------

-- Detect active Claude terminal buffers with process liveness check
local function detect_active_claude()
  local ok, session_manager = pcall(require, "neotex.plugins.ai.claude.core.session-manager")
  if not ok then
    return false, {}
  end
  local claude_buffers = session_manager.detect_claude_buffers()
  local active = {}
  for _, bufnr in ipairs(claude_buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local channel = vim.api.nvim_buf_get_option(bufnr, "channel")
      if channel and channel > 0 then
        local status = vim.fn.jobwait({ channel }, 0)
        if status[1] == -1 then
          table.insert(active, bufnr)
        end
      end
    end
  end
  return #active > 0, active
end

-- Detect active OpenCode terminal using snacks.terminal.list()
local function detect_active_opencode()
  local ok, snacks_term = pcall(require, "snacks.terminal")
  if not ok or not snacks_term.list then
    return false, {}
  end
  local all_terms = snacks_term.list()
  local active = {}
  for _, term in ipairs(all_terms) do
    local buf = term.buf
    if buf and vim.api.nvim_buf_is_valid(buf) then
      local snacks_data = vim.b[buf].snacks_terminal
      if snacks_data then
        local cmd = snacks_data.cmd or snacks_data.args or {}
        local cmd_str = type(cmd) == "table" and table.concat(cmd, " ") or tostring(cmd)
        if cmd_str:match("opencode%s+%-%-port") then
          table.insert(active, buf)
        end
      end
    end
  end
  return #active > 0, active
end

-----------------------------------------------------------------------
-- STAGE 1: TOOL PICKER (vim.ui.select)
-----------------------------------------------------------------------

function M.show_tool_picker()
  ensure_data_dir()
  load_tool_prefs()

  local items = {
    { label = "ClaudeCode", value = "claude" },
    { label = "OpenCode", value = "opencode" },
  }

  -- Reorder to show last-selected tool first
  if tool_prefs.last_tool == "opencode" then
    items = { items[2], items[1] }
  end

  vim.ui.select(items, {
    prompt = "Select AI tool:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    save_tool_prefs(choice.value)
    if choice.value == "claude" then
      M.show_claude_session_picker()
    elseif choice.value == "opencode" then
      M.show_opencode_session_picker()
    end
  end)
end

-----------------------------------------------------------------------
-- UNIFIED COMMANDS LOADER PICKER (<leader>al)
-----------------------------------------------------------------------

function M.show_commands_picker()
  ensure_data_dir()
  load_tool_prefs()
  local mode = vim.api.nvim_get_mode().mode

  local items = {
    { label = "ClaudeCode", value = "claude" },
    { label = "OpenCode", value = "opencode" },
  }
  if tool_prefs.last_tool == "opencode" then
    items = { items[2], items[1] }
  end

  vim.ui.select(items, {
    prompt = "Select AI commands:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    save_tool_prefs(choice.value)
    if mode == "v" or mode == "V" or mode == "\22" then
      if choice.value == "claude" then
        require("neotex.plugins.ai.claude.core.visual").send_visual_to_claude_with_prompt()
      else
        require("neotex.plugins.ai.opencode.core.visual").send_visual_to_opencode_with_prompt()
      end
    else
      vim.cmd(choice.value == "claude" and "ClaudeCommands" or "OpencodeCommands")
    end
  end)
end

-----------------------------------------------------------------------
-- STAGE 2: CLAUDE PATH (delegate to existing picker)
-----------------------------------------------------------------------

function M.show_claude_session_picker()
  local ok, claude_session = pcall(require, "neotex.plugins.ai.claude.core.session")
  if ok and claude_session.show_session_picker then
    claude_session.show_session_picker()
  else
    vim.notify("Claude session picker not available", vim.log.levels.ERROR)
  end
end

-----------------------------------------------------------------------
-- STAGE 2: OPENCODE PATH (Telescope dropdown with 3 options)
-----------------------------------------------------------------------

function M.show_opencode_session_picker()
  -- Try to load OpenCode last session info for the "restore" option
  local last_session_data = atomic_read(opencode_session_file)
  local age_text = ""
  local last_session_id = nil
  if last_session_data and last_session_data.session_id then
    last_session_id = last_session_data.session_id
    local age = os.time() - (last_session_data.timestamp or 0)
    if age < 60 then
      age_text = "just now"
    elseif age < 3600 then
      age_text = string.format("%d min ago", math.floor(age / 60))
    elseif age < 86400 then
      age_text = string.format("%d hr ago", math.floor(age / 3600))
    else
      age_text = string.format("%d days ago", math.floor(age / 86400))
    end
  end

  local opencode_mod = require("opencode")

  local options = {
    {
      display = "Create new session",
      value = "new",
      ord = "Create new session",
    },
    {
      display = last_session_id
        and string.format("Restore last session (%s)", age_text)
        or "Restore last session (none yet)",
      value = "restore",
      ord = "Restore last session",
    },
    {
      display = "Browse all sessions",
      value = "browse",
      ord = "Browse all sessions",
    },
  }

  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  pickers.new(require("telescope.themes").get_dropdown({
    winblend = 10,
    width = 0.5,
    previewer = false,
    layout_config = {
      width = 60,
      height = 10,
    },
  }), {
    prompt_title = "OpenCode Session",
    finder = finders.new_table({
      results = options,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.ord,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          return
        end
        local choice = selection.value.value

        -- Toggle opens the terminal (defaults to new session in TUI)
        opencode_mod.toggle()

        if choice == "restore" then
          if last_session_id then
            local server_mod = require("opencode.server")
            server_mod.get()
              :next(function(server)
                server:select_session(last_session_id)
              end)
              :catch(function(err)
                if err then
                  vim.notify(
                    "Failed to restore session: " .. tostring(err),
                    vim.log.levels.ERROR,
                    { title = "OpenCode" }
                  )
                end
              end)
          else
            vim.notify("No previous OpenCode session to restore", vim.log.levels.WARN)
          end
        elseif choice == "browse" then
          opencode_mod.select_session()
        end
        -- "new" needs no follow-up: toggle() already opens a fresh session in the TUI
      end)
      return true
    end,
  }):find()
end

-----------------------------------------------------------------------
-- SMART TOGGLE (primary entry point)
-----------------------------------------------------------------------

function M.smart_toggle()
  ensure_data_dir()
  load_tool_prefs()

  local has_claude, _ = detect_active_claude()
  local has_opencode, _ = detect_active_opencode()

  -- If only one tool is visible, toggle that tool directly
  if has_claude and not has_opencode then
    local ok = pcall(require, "neotex.plugins.ai.claude.core.claude-code")
    if ok then
      vim.cmd("ClaudeCode")
    end
    return
  end

  if has_opencode and not has_claude then
    local ok, opencode_mod = pcall(require, "opencode")
    if ok then
      opencode_mod.toggle()
    end
    return
  end

  -- Both visible or neither visible: show Stage 1 picker
  M.show_tool_picker()
end

-----------------------------------------------------------------------
-- SETUP
-----------------------------------------------------------------------

-- Shortcut alias for ensure_data_dir (used in show_tool_picker)
local function ensure_dir()
  ensure_data_dir()
end
M._ensure_dir = ensure_dir

function M.setup()
  if M._initialized then
    return
  end
  M._initialized = true

  ensure_data_dir()
  load_tool_prefs()

  -- Register OpenCodeEvent:session.idle autocmd to track last session
  vim.api.nvim_create_augroup("NixAIOpencodeSession", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = "NixAIOpencodeSession",
    pattern = "OpencodeEvent:session.idle",
    callback = function(event)
      local session_id = nil
      local data = event.data
      if type(data) == "string" then
        session_id = data
      elseif type(data) == "table" then
        session_id = data.session_id or data.id or data.session
      end
      if session_id then
        ensure_data_dir()
        atomic_write(opencode_session_file, {
          session_id = session_id,
          timestamp = os.time(),
        })
      end
    end,
  })
end

return M
