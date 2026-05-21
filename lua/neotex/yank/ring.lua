local M = {}

local _config = {
  max_size = 50,
}

local _entries = {}

local function _is_duplicate(entry)
  if #_entries == 0 then
    return false
  end
  return _entries[1].regcontents == entry.regcontents
end

function M.setup(opts)
  _config = vim.tbl_deep_extend("force", _config, opts or {})
  _entries = {}
end

function M.push(entry)
  if _is_duplicate(entry) then
    return
  end
  table.insert(_entries, 1, entry)
  if #_entries > _config.max_size then
    table.remove(_entries)
  end
end

function M.all()
  return _entries
end

function M.get(index)
  return _entries[index]
end

function M.count()
  return #_entries
end

function M.clear()
  _entries = {}
end

return M
