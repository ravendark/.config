--- neotex.yank.clipboard
--- Non-blocking system clipboard integration via vim.system().
--- Solves the post-sleep Wayland hang by never calling vim.fn.getreg('+')
--- on FocusGained. Instead uses wl-paste/xclip with a hard timeout.

local M = {}

M._last_clipboard = nil
M._timeout_ms = 2000
M._enabled = true

--- Detect the clipboard read command based on the display server.
--- @return string[]|nil
local function get_paste_cmd()
  if vim.env.WAYLAND_DISPLAY then
    return { "wl-paste", "--no-newline" }
  elseif vim.env.DISPLAY then
    if vim.fn.executable("xclip") == 1 then
      return { "xclip", "-selection", "clipboard", "-o" }
    elseif vim.fn.executable("xsel") == 1 then
      return { "xsel", "--clipboard", "--output" }
    end
  end
  return nil
end

--- Detect the clipboard write command.
--- @return string[]|nil
local function get_copy_cmd()
  if vim.env.WAYLAND_DISPLAY then
    return { "wl-copy" }
  elseif vim.env.DISPLAY then
    if vim.fn.executable("xclip") == 1 then
      return { "xclip", "-selection", "clipboard" }
    elseif vim.fn.executable("xsel") == 1 then
      return { "xsel", "--clipboard", "--input" }
    end
  end
  return nil
end

--- Configure the clipboard module.
--- @param opts { timeout_ms?: integer, enabled?: boolean }
function M.setup(opts)
  opts = opts or {}
  M._timeout_ms = opts.timeout_ms or 2000
  M._enabled = opts.enabled ~= false
end

--- Read the system clipboard asynchronously.
--- Calls callback(content) on success, callback(nil) on failure/timeout.
--- @param callback fun(content: string|nil)
function M.read_async(callback)
  if not M._enabled then
    callback(nil)
    return
  end

  local cmd = get_paste_cmd()
  if not cmd then
    local ok, content = pcall(vim.fn.getreg, "+")
    callback(ok and content or nil)
    return
  end

  vim.system(cmd, {
    text = true,
    timeout = M._timeout_ms,
  }, function(obj)
    vim.schedule(function()
      if obj.code == 0 and obj.stdout then
        callback(obj.stdout)
      elseif obj.code == 124 then
        vim.notify(
          "[yank] Clipboard read timed out (post-sleep?). Skipping sync.",
          vim.log.levels.DEBUG
        )
        callback(nil)
      else
        callback(nil)
      end
    end)
  end)
end

--- Read clipboard synchronously with timeout (for initial startup).
--- @param timeout_ms? integer Override timeout
--- @return string|nil content
function M.read_sync(timeout_ms)
  if not M._enabled then
    return nil
  end

  local cmd = get_paste_cmd()
  if not cmd then
    local ok, content = pcall(vim.fn.getreg, "+")
    return ok and content or nil
  end

  local obj = vim.system(cmd, {
    text = true,
    timeout = timeout_ms or M._timeout_ms,
  }):wait()

  if obj.code == 0 and obj.stdout then
    return obj.stdout
  end
  return nil
end

--- Write content to the system clipboard.
--- @param content string
function M.write(content)
  local cmd = get_copy_cmd()
  if not cmd then
    pcall(vim.fn.setreg, "+", content)
    return
  end

  vim.system(cmd, {
    stdin = content,
    text = true,
    timeout = M._timeout_ms,
  })
end

--- Check if system clipboard has new content and push to ring.
--- Called on FocusGained. Non-blocking replacement for yanky's sync.
--- @param ring table The ring module (neotex.yank.ring)
function M.sync_to_ring(ring)
  M.read_async(function(content)
    if not content then
      return
    end

    if content ~= M._last_clipboard then
      M._last_clipboard = content
      local regtype = content:find("\n") and "V" or "v"
      ring.push({
        regcontents = content,
        regtype = regtype,
      })
    end
  end)
end

--- Update the tracked clipboard state (call after local yanks).
--- @param content string
function M.update_last(content)
  M._last_clipboard = content
end

return M
