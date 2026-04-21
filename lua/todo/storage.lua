local M = {}

local function get_data_path()
  return vim.fn.stdpath("data") .. "/todo.json"
end

local function migrate(data)
  -- Old format was a flat array of {text, done} objects
  if vim.islist(data) then
    return { folders = { { name = "global", todos = data } } }
  end
  return data
end

function M.load()
  local path = get_data_path()
  local f = io.open(path, "r")
  if not f then
    return { folders = { { name = "global", todos = {} } } }
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return { folders = { { name = "global", todos = {} } } }
  end
  return migrate(data)
end

function M.save(data)
  local path = get_data_path()
  local f = io.open(path, "w")
  if not f then
    vim.notify("todo.nvim: failed to save " .. path, vim.log.levels.ERROR)
    return
  end
  f:write(vim.json.encode(data))
  f:close()
end

return M
