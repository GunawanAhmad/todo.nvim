local storage = require("todo.storage")

local M = {}

local state = {
  buf = nil,
  win = nil,
  todos = {},
}

local function is_open()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  vim.bo[state.buf].modifiable = true
  local lines = {}
  for i, todo in ipairs(state.todos) do
    local check = todo.done and "[x]" or "[ ]"
    table.insert(lines, string.format("%d. %s %s", i, check, todo.text))
  end
  if #lines == 0 then
    lines = { "  No todos yet. Press 'a' to add one." }
  end
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
end

local function close()
  if is_open() then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

local function add_todo()
  vim.ui.input({ prompt = "New todo: " }, function(input)
    if not input or input == "" then return end
    table.insert(state.todos, { text = input, done = false })
    storage.save(state.todos)
    render()
  end)
end

local function edit_todo()
  if #state.todos == 0 then return end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  local todo = state.todos[row]
  if not todo then return end
  vim.ui.input({ prompt = "Edit todo: ", default = todo.text }, function(input)
    if not input or input == "" then return end
    todo.text = input
    storage.save(state.todos)
    render()
  end)
end

local function toggle_todo()
  if #state.todos == 0 then return end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  local todo = state.todos[row]
  if not todo then return end
  todo.done = not todo.done
  storage.save(state.todos)
  render()
end

local function delete_todo()
  if #state.todos == 0 then return end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  table.remove(state.todos, row)
  storage.save(state.todos)
  render()
  -- keep cursor in bounds
  local count = #state.todos
  if count > 0 then
    local new_row = math.min(row, count)
    vim.api.nvim_win_set_cursor(state.win, { new_row, 0 })
  end
end

local function clear_done()
  local kept = {}
  for _, t in ipairs(state.todos) do
    if not t.done then table.insert(kept, t) end
  end
  state.todos = kept
  storage.save(state.todos)
  render()
end

local function set_keymaps()
  local opts = { buffer = state.buf, nowait = true, silent = true }
  local maps = {
    { "n", "a",     add_todo },
    { "n", "e",     edit_todo },
    { "n", "<CR>",  toggle_todo },
    { "n", "x",     toggle_todo },
    { "n", "d",     delete_todo },
    { "n", "D",     clear_done },
    { "n", "q",     close },
    { "n", "<Esc>", close },
  }
  for _, m in ipairs(maps) do
    vim.keymap.set(m[1], m[2], m[3], opts)
  end
end

local function create_win()
  local width  = math.min(60, math.floor(vim.o.columns * 0.6))
  local height = math.min(20, math.floor(vim.o.lines * 0.5))
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].filetype    = "todo"
  vim.bo[state.buf].bufhidden   = "wipe"
  vim.bo[state.buf].modifiable  = false

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width    = width,
    height   = height,
    row      = row,
    col      = col,
    style    = "minimal",
    border   = "rounded",
    title    = " Todo List ",
    title_pos = "center",
  })

  vim.wo[state.win].cursorline = true
  vim.wo[state.win].wrap       = true
  vim.wo[state.win].linebreak  = true

  set_keymaps()

  -- close on focus lost
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.buf,
    once   = true,
    callback = function() close() end,
  })
end

function M.toggle()
  if is_open() then
    close()
    return
  end
  state.todos = storage.load()
  create_win()
  render()
end

return M
