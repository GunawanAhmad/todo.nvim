local M = {}

local function get_global_path()
  return vim.fn.stdpath("data") .. "/todo.json"
end

local function get_projects_dir()
  return vim.fn.stdpath("data") .. "/todo/projects"
end

local function sanitize(path)
  return path:gsub("^/", ""):gsub("/", "-")
end

local function get_git_root()
  local result = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 then return nil end
  return vim.trim(result)
end

local function migrate(data)
  if vim.islist(data) then
    return { folders = { { name = "global", todos = data } } }
  end
  return data
end

local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  return (ok and type(data) == "table") and data or nil
end

local function write(path, data)
  local f = io.open(path, "w")
  if not f then
    vim.notify("todo.nvim: failed to save " .. path, vim.log.levels.ERROR)
    return false
  end
  f:write(vim.json.encode(data))
  f:close()
  return true
end

local function empty()
  return { folders = { { name = "global", todos = {} } } }
end

-- ─── global ──────────────────────────────────────────────────────────────────

function M.load()
  local data = read(get_global_path())
  return migrate(data or empty())
end

function M.save(data)
  write(get_global_path(), data)
end

-- ─── project (by path) ───────────────────────────────────────────────────────

function M.load_from_path(path)
  local data = read(path)
  return data and migrate(data) or nil
end

function M.save_to_path(data, path)
  write(path, data)
end

-- ─── project (current git root) ──────────────────────────────────────────────

function M.project_path()
  local root = get_git_root()
  if not root then return nil end
  return get_projects_dir() .. "/" .. sanitize(root) .. ".json"
end

function M.project_exists()
  local path = M.project_path()
  return path ~= nil and vim.fn.filereadable(path) == 1
end

-- Returns ok, message
function M.init_project()
  local root = get_git_root()
  if not root then
    return false, "not in a git repository"
  end
  vim.fn.mkdir(get_projects_dir(), "p")
  local path = get_projects_dir() .. "/" .. sanitize(root) .. ".json"
  if vim.fn.filereadable(path) == 1 then
    return false, "project todo already exists for " .. root
  end
  local data = empty()
  data.root = root  -- store root so the picker can show real paths
  write(path, data)
  return true, root
end

-- Returns list of { name, path } for all initialized projects.
function M.list_projects()
  local dir   = get_projects_dir()
  local files = vim.fn.glob(dir .. "/*.json", false, true)
  local out   = {}
  for _, path in ipairs(files) do
    local data = read(path)
    local name = (data and data.root) or path:match("([^/]+)%.json$") or path
    table.insert(out, { name = name, path = path })
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

return M
