--- neotex.yank.ring
--- Fixed-size circular buffer for yank history.

local M = {}

--- @class YankEntry
--- @field regcontents string
--- @field regtype string
--- @field filetype string|nil
--- @field timestamp number

--- @type YankEntry[]
M._entries = {}
M._max_size = 50

--- Configure the ring buffer size.
--- @param opts { max_size?: integer }
function M.setup(opts)
  opts = opts or {}
  M._max_size = opts.max_size or 50
  M._entries = {}
end

--- Push a new entry, deduplicating against the most recent.
--- @param entry YankEntry
--- @return boolean pushed Whether the entry was actually added
function M.push(entry)
  if not entry or not entry.regcontents or entry.regcontents == "" then
    return false
  end

  local top = M._entries[1]
  if top and top.regcontents == entry.regcontents and top.regtype == entry.regtype then
    return false
  end

  table.insert(M._entries, 1, {
    regcontents = entry.regcontents,
    regtype = entry.regtype,
    filetype = entry.filetype or vim.bo.filetype,
    timestamp = vim.uv.now(),
  })

  while #M._entries > M._max_size do
    table.remove(M._entries)
  end

  return true
end

--- Get all entries (most recent first).
--- @return YankEntry[]
function M.all()
  return M._entries
end

--- Get entry at index (1-based, 1 = most recent).
--- @param index integer
--- @return YankEntry|nil
function M.get(index)
  return M._entries[index]
end

--- Get the number of entries.
--- @return integer
function M.count()
  return #M._entries
end

--- Clear all entries.
function M.clear()
  M._entries = {}
end

return M
