local storage = require("todo.storage")

local M = {}

local hl_ns = vim.api.nvim_create_namespace("todo_nvim")

local state = {
  buf       = nil,
  win       = nil,
  data      = nil,  -- { folders = [{name, todos}] }
  collapsed = {},   -- { [folder_idx] = bool }
  line_map  = {},   -- { [line_nr] = {type, folder_idx, todo_idx?} }
}

-- ─── rendering ───────────────────────────────────────────────────────────────

local function build_lines()
  local lines    = {}
  state.line_map = {}

  for fi, folder in ipairs(state.data.folders) do
    local done_count = 0
    for _, t in ipairs(folder.todos) do
      if t.done then done_count = done_count + 1 end
    end
    local total     = #folder.todos
    local collapsed = state.collapsed[fi]
    local icon      = collapsed and "▸" or "▾"
    table.insert(lines, string.format("  %s %s  (%d/%d)", icon, folder.name, done_count, total))
    state.line_map[#lines] = { type = "folder", folder_idx = fi }

    if not collapsed then
      if total == 0 then
        table.insert(lines, "      (empty — press 'a' to add)")
        state.line_map[#lines] = { type = "empty", folder_idx = fi }
      else
        for ti, todo in ipairs(folder.todos) do
          local check = todo.done and "[x]" or "[ ]"
          table.insert(lines, string.format("    %s %s", check, todo.text))
          state.line_map[#lines] = { type = "todo", folder_idx = fi, todo_idx = ti }
        end
      end
    end
  end

  if #lines == 0 then
    lines = { "  No folders yet. Press 'A' to add one." }
    state.line_map[1] = { type = "empty_root" }
  end

  return lines
end

local function apply_highlights(lines)
  vim.api.nvim_buf_clear_namespace(state.buf, hl_ns, 0, -1)
  for lnr, item in pairs(state.line_map) do
    if item.type == "folder" then
      vim.api.nvim_buf_add_highlight(state.buf, hl_ns, "Title", lnr - 1, 0, -1)
    elseif item.type == "todo" then
      local todo = state.data.folders[item.folder_idx].todos[item.todo_idx]
      if todo.done then
        vim.api.nvim_buf_add_highlight(state.buf, hl_ns, "Comment", lnr - 1, 0, -1)
      end
    elseif item.type == "empty" then
      vim.api.nvim_buf_add_highlight(state.buf, hl_ns, "Comment", lnr - 1, 0, -1)
    end
  end
end

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  local lines = build_lines()
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  apply_highlights(lines)
end

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function is_open()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function close()
  if is_open() then vim.api.nvim_win_close(state.win, true) end
  state.win = nil
end

local function cursor_item()
  if not is_open() then return nil end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  return state.line_map[row], row
end

-- Return the folder_idx that owns the cursor position.
local function cursor_folder_idx()
  local item = cursor_item()
  if item then return item.folder_idx end
  return #state.data.folders > 0 and 1 or nil
end

-- ─── actions ─────────────────────────────────────────────────────────────────

local function add_todo()
  local fi = cursor_folder_idx()
  if not fi then return end
  vim.ui.input({ prompt = "New todo: " }, function(text)
    if not text or text == "" then return end
    table.insert(state.data.folders[fi].todos, { text = text, done = false })
    state.collapsed[fi] = false
    storage.save(state.data)
    render()
  end)
end

local function add_folder()
  vim.ui.input({ prompt = "Folder name: " }, function(name)
    if not name or name == "" then return end
    table.insert(state.data.folders, { name = name, todos = {} })
    storage.save(state.data)
    render()
  end)
end

local function toggle_item()
  local item = cursor_item()
  if not item then return end

  if item.type == "folder" then
    state.collapsed[item.folder_idx] = not state.collapsed[item.folder_idx]
    render()
  elseif item.type == "todo" then
    local todo = state.data.folders[item.folder_idx].todos[item.todo_idx]
    todo.done = not todo.done
    storage.save(state.data)
    render()
  end
end

local function toggle_done_only()
  local item = cursor_item()
  if not item or item.type ~= "todo" then return end
  local todo = state.data.folders[item.folder_idx].todos[item.todo_idx]
  todo.done = not todo.done
  storage.save(state.data)
  render()
end

local function edit_item()
  local item = cursor_item()
  if not item then return end

  if item.type == "folder" then
    local folder = state.data.folders[item.folder_idx]
    vim.ui.input({ prompt = "Rename folder: ", default = folder.name }, function(name)
      if not name or name == "" then return end
      folder.name = name
      storage.save(state.data)
      render()
    end)
  elseif item.type == "todo" then
    local todo = state.data.folders[item.folder_idx].todos[item.todo_idx]
    vim.ui.input({ prompt = "Edit todo: ", default = todo.text }, function(text)
      if not text or text == "" then return end
      todo.text = text
      storage.save(state.data)
      render()
    end)
  end
end

local function delete_item()
  local item, row = cursor_item()
  if not item then return end

  if item.type == "folder" then
    local folder = state.data.folders[item.folder_idx]
    local function do_delete()
      table.remove(state.data.folders, item.folder_idx)
      state.collapsed[item.folder_idx] = nil
      storage.save(state.data)
      render()
    end
    if #folder.todos > 0 then
      vim.ui.input(
        { prompt = string.format("Delete '%s' with %d todo(s)? (y/N): ", folder.name, #folder.todos) },
        function(ans)
          if ans and ans:lower() == "y" then do_delete() end
        end
      )
    else
      do_delete()
    end

  elseif item.type == "todo" then
    local todos = state.data.folders[item.folder_idx].todos
    table.remove(todos, item.todo_idx)
    storage.save(state.data)
    render()
    -- keep cursor in bounds
    local new_row = math.min(row, vim.api.nvim_buf_line_count(state.buf))
    pcall(vim.api.nvim_win_set_cursor, state.win, { new_row, 0 })
  end
end

local function clear_done()
  local fi = cursor_folder_idx()
  if not fi then return end
  local folder = state.data.folders[fi]
  local kept = {}
  for _, t in ipairs(folder.todos) do
    if not t.done then table.insert(kept, t) end
  end
  folder.todos = kept
  storage.save(state.data)
  render()
end

-- ─── window ──────────────────────────────────────────────────────────────────

local function set_keymaps()
  local opts = { buffer = state.buf, nowait = true, silent = true }
  local maps = {
    { "a",     add_todo },
    { "A",     add_folder },
    { "<CR>",  toggle_item },
    { "<Space>", toggle_item },
    { "x",     toggle_done_only },
    { "e",     edit_item },
    { "d",     delete_item },
    { "D",     clear_done },
    { "q",     close },
    { "<Esc>", close },
  }
  for _, m in ipairs(maps) do
    vim.keymap.set("n", m[1], m[2], opts)
  end
end

local function create_win()
  local width  = math.min(60, math.floor(vim.o.columns * 0.6))
  local height = math.min(30, math.floor(vim.o.lines * 0.6))
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].filetype   = "todo"
  vim.bo[state.buf].bufhidden  = "wipe"
  vim.bo[state.buf].modifiable = false

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    style     = "minimal",
    border    = "rounded",
    title     = " Todo ",
    title_pos = "center",
  })

  vim.wo[state.win].cursorline = true
  vim.wo[state.win].wrap       = false

  set_keymaps()

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer   = state.buf,
    once     = true,
    callback = function() close() end,
  })
end

-- ─── public API ──────────────────────────────────────────────────────────────

-- opts.focus_folder: name of folder to jump cursor to after opening
function M.toggle(opts)
  opts = opts or {}

  if is_open() then
    close()
    return
  end

  state.data      = storage.load()
  state.collapsed = {}

  if not state.data.folders or #state.data.folders == 0 then
    state.data.folders = { { name = "global", todos = {} } }
    storage.save(state.data)
  end

  create_win()
  render()

  if opts.focus_folder then
    for lnr, item in pairs(state.line_map) do
      if item.type == "folder" then
        local folder = state.data.folders[item.folder_idx]
        if folder and folder.name == opts.focus_folder then
          pcall(vim.api.nvim_win_set_cursor, state.win, { lnr, 0 })
          break
        end
      end
    end
  end
end

return M
