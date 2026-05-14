-----------------------------------------------------------
-- Discord Link
--
-- Links an OpenCode session to a Discord thread via the
-- bot's HTTP API. Discovers the TUI's embedded server port
-- dynamically and queries it for sessions.
--
-- Environment variables:
--   DISCORD_BOT_URL        - Bot API base URL (default: http://localhost:8080)
--   DISCORD_BOT_LINK_TOKEN - Bearer token for API auth
--
-- Usage:
--   require("neotex.plugins.ai.opencode.discord-link").link_current_session()
-----------------------------------------------------------

local M = {}

local BOT_URL = vim.env.DISCORD_BOT_URL or "http://localhost:8080"
local TOKEN = vim.env.DISCORD_BOT_LINK_TOKEN

--- @return string|nil
local function _auth_header()
  if not TOKEN or TOKEN == "" then return nil end
  return "Bearer " .. TOKEN
end

--- Make an HTTP request via curl.
--- @param method string
--- @param url string
--- @param headers table<string,string>
--- @param body table|nil
--- @param callback function(err, data)
local function _http(method, url, headers, body, callback)
  local cmd = {
    "curl", "-s", "-S", "-X", method,
    "-w", "\n%{http_code}",
    "--connect-timeout", "5", "--max-time", "10",
  }
  for k, v in pairs(headers) do
    table.insert(cmd, "-H")
    table.insert(cmd, k .. ": " .. v)
  end
  if body then
    local ok, encoded = pcall(vim.fn.json_encode, body)
    if not ok then
      vim.schedule(function() callback("Failed to encode body", nil) end)
      return
    end
    table.insert(cmd, "-H")
    table.insert(cmd, "Content-Type: application/json")
    table.insert(cmd, "-d")
    table.insert(cmd, encoded)
  end
  table.insert(cmd, url)

  local stdout_chunks = {}
  local stderr_chunks = {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(stdout_chunks, line) end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(stderr_chunks, line) end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          callback("curl failed: " .. table.concat(stderr_chunks, "\n"), nil)
          return
        end
        local http_code = stdout_chunks[#stdout_chunks]
        table.remove(stdout_chunks, #stdout_chunks)
        local response_body = table.concat(stdout_chunks, "\n")
        local status = tonumber(http_code) or 0
        if status < 200 or status >= 300 then
          callback("HTTP " .. status .. ": " .. response_body, nil)
          return
        end
        if response_body == "" then
          callback(nil, {})
          return
        end
        local ok_json, parsed = pcall(vim.fn.json_decode, response_body)
        if not ok_json then
          callback("Failed to parse JSON", nil)
          return
        end
        callback(nil, parsed)
      end)
    end,
  })
end

--- Discover the OpenCode TUI server port for the current working directory.
--- Uses `ss` to find opencode processes and matches by working directory.
--- @param callback function(err, server_url)
local function _discover_tui_port(callback)
  local cwd = vim.fn.getcwd()

  -- Find opencode processes with --port flag (TUI instances), get their PIDs and ports
  local cmd = { "bash", "-c", [[
    ss -tlnp 2>/dev/null | grep opencode | while read -r line; do
      port=$(echo "$line" | grep -oP ':\K\d+(?=\s)')
      pid=$(echo "$line" | grep -oP 'pid=\K\d+')
      if [ -n "$port" ] && [ -n "$pid" ]; then
        # Get the working directory of this process
        proc_cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null)
        # Get the command line to distinguish TUI (--port) from serve
        proc_cmd=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ')
        echo "$port|$pid|$proc_cwd|$proc_cmd"
      fi
    done
  ]] }

  local stdout_chunks = {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(stdout_chunks, line) end
        end
      end
    end,
    on_exit = function()
      vim.schedule(function()
        local best_port = nil
        local best_is_cwd = false

        for _, line in ipairs(stdout_chunks) do
          local port, _, proc_cwd, proc_cmd = line:match("^(%d+)|(%d+)|(.-)|(.*)")
          if port then
            -- Skip the headless serve instances
            local is_serve = proc_cmd:match("serve")
            if not is_serve then
              local is_cwd = (proc_cwd == cwd)
              if is_cwd or not best_port then
                best_port = port
                best_is_cwd = is_cwd
              end
              -- Exact CWD match is ideal
              if is_cwd then break end
            end
          end
        end

        if best_port then
          callback(nil, "http://127.0.0.1:" .. best_port)
        else
          callback("No OpenCode TUI found -- open OpenCode first", nil)
        end
      end)
    end,
  })
end

--- Fetch sessions from an OpenCode server, with the active session first.
--- @param server_url string
--- @param callback function(err, sessions)
local function _fetch_sessions(server_url, callback)
  -- First get session status to find the active/busy session
  _http("GET", server_url .. "/session/status", {}, nil, function(_, status_data)
    local busy_ids = {}
    if type(status_data) == "table" then
      for sid, info in pairs(status_data) do
        if type(info) == "table" and info.type == "busy" then
          busy_ids[sid] = true
        end
      end
    end

    _http("GET", server_url .. "/session", {}, nil, function(err, data)
      if err then
        callback(err, nil)
        return
      end
      if type(data) ~= "table" then
        callback("Unexpected response", nil)
        return
      end
      -- Tag busy sessions and sort: busy first, then newest first
      for _, sess in ipairs(data) do
        if busy_ids[sess.id] then sess._busy = true end
      end
      table.sort(data, function(a, b)
        local a_busy = a._busy and 1 or 0
        local b_busy = b._busy and 1 or 0
        if a_busy ~= b_busy then return a_busy > b_busy end
        local at = (a.time or {}).updated or 0
        local bt = (b.time or {}).updated or 0
        return at > bt
      end)
      callback(nil, data)
    end)
  end)
end

--- Link a session via the bot API, including the server URL.
--- @param session_id string
--- @param session_name string
--- @param server_url string
--- @param directory string|nil
local function _link_session(session_id, session_name, server_url, directory)
  local auth = _auth_header()
  if not auth then
    vim.notify("DISCORD_BOT_LINK_TOKEN not set", vim.log.levels.ERROR)
    return
  end

  _http("POST", BOT_URL .. "/link", { Authorization = auth }, {
    session_id = session_id,
    session_name = session_name,
    server_url = server_url,
    directory = directory or "",
  }, function(err, data)
    if err then
      if err:match("409") then
        vim.notify("Session already linked (same port)", vim.log.levels.INFO)
      else
        vim.notify(err, vim.log.levels.ERROR)
      end
      return
    end
    local thread_url = data and data.thread_url or ""
    local updated = data and data.updated
    if thread_url ~= "" then
      vim.fn.setreg("+", thread_url)
      if updated then
        vim.notify("Port updated: " .. thread_url .. " (copied)", vim.log.levels.INFO)
      else
        vim.notify("Linked: " .. thread_url .. " (copied)", vim.log.levels.INFO)
      end
    else
      vim.notify("Session linked to Discord", vim.log.levels.INFO)
    end
  end)
end

--- Format age from millisecond timestamp.
--- @param ms number
--- @return string
local function _format_age(ms)
  if not ms or ms == 0 then return "-" end
  local secs = os.time() - math.floor(ms / 1000)
  if secs < 0 then secs = 0 end
  if secs < 60 then return "just now"
  elseif secs < 3600 then return math.floor(secs / 60) .. "m ago"
  elseif secs < 86400 then return math.floor(secs / 3600) .. "h ago"
  else return math.floor(secs / 86400) .. "d ago"
  end
end

--- Show a Telescope picker to select a session, then link it.
--- @param sessions table
--- @param server_url string
local function _pick_and_link(sessions, server_url)
  local ok_pickers, pickers = pcall(require, "telescope.pickers")
  local ok_finders, finders = pcall(require, "telescope.finders")
  local ok_actions, actions = pcall(require, "telescope.actions")
  local ok_state, action_state = pcall(require, "telescope.actions.state")
  local ok_conf, conf_mod = pcall(require, "telescope.config")
  local ok_prev, previewers = pcall(require, "telescope.previewers")

  if not (ok_pickers and ok_finders and ok_actions and ok_state and ok_conf) then
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return
  end

  -- Limit to 20 most recent (already sorted newest-first)
  local capped = {}
  for i = 1, math.min(#sessions, 20) do
    table.insert(capped, sessions[i])
  end

  pickers.new({}, {
    prompt_title = "Link Session to Discord",
    sorting_strategy = "descending",
    finder = finders.new_table({
      results = capped,
      entry_maker = function(sess)
        local title = sess.title or sess.id
        local updated = (sess.time or {}).updated or 0
        local age = _format_age(updated)
        local prefix = sess._busy and "[active] " or ""
        return {
          value = sess,
          display = string.format("%s%-45s %s", prefix, title:sub(1, 45), age),
          ordinal = title .. " " .. sess.id,
        }
      end,
    }),
    sorter = conf_mod.values.generic_sorter({}),
    previewer = ok_prev and previewers.new_buffer_previewer({
      title = "Session Details",
      define_preview = function(self, entry)
        local sess = entry.value
        if not sess then return end
        local lines = {
          "Session Details",
          string.rep("=", 50),
          "",
          "Title:      " .. (sess.title or "-"),
          "ID:         " .. (sess.id or "-"),
          "Directory:  " .. (sess.directory or "-"),
          "Status:     " .. (sess._busy and "busy" or "idle"),
          "Updated:    " .. _format_age((sess.time or {}).updated or 0),
          "Created:    " .. _format_age((sess.time or {}).created or 0),
          "",
        }
        local summary = sess.summary or {}
        if summary.additions or summary.deletions then
          table.insert(lines, string.format("Changes:    +%d -%d (%d files)",
            summary.additions or 0, summary.deletions or 0, summary.files or 0))
          table.insert(lines, "")
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end,
    }) or nil,
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        if not entry then return end
        actions.close(prompt_bufnr)
        local sess = entry.value
        _link_session(sess.id, sess.title or sess.id, server_url, sess.directory)
      end)
      return true
    end,
  }):find()
end

--- Link the current OpenCode session to a Discord thread.
function M.link_current_session()
  vim.notify("Discovering OpenCode server...", vim.log.levels.INFO)

  _discover_tui_port(function(err, server_url)
    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end

    vim.notify("Fetching sessions from " .. server_url .. "...", vim.log.levels.INFO)

    _fetch_sessions(server_url, function(fetch_err, sessions)
      if fetch_err then
        vim.notify(fetch_err, vim.log.levels.ERROR)
        return
      end

      if not sessions or #sessions == 0 then
        vim.notify("No sessions found -- create one first", vim.log.levels.WARN)
        return
      end

      if #sessions == 1 then
        local sess = sessions[1]
        _link_session(sess.id, sess.title or sess.id, server_url, sess.directory)
      else
        _pick_and_link(sessions, server_url)
      end
    end)
  end)
end

return M
