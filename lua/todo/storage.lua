local M = {}

local function get_data_path()
  return vim.fn.stdpath("data") .. "/todo.json"
end

function M.load()
  local path = get_data_path()
  local f = io.open(path, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  return (ok and type(data) == "table") and data or {}
end

function M.save(todos)
  local path = get_data_path()
  local f = io.open(path, "w")
  if not f then
    vim.notify("todo.nvim: failed to save " .. path, vim.log.levels.ERROR)
    return
  end
  f:write(vim.json.encode(todos))
  f:close()
end

return M
