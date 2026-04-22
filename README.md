# todo.nvim

A persistent todo list for Neovim with folder organization and per-project todos — accessible from anywhere via a floating window.

## Features

- Floating window accessible from any buffer
- Organize todos into folders with a navigable tree (expand/collapse like nvim-tree)
- Global todos always available, plus opt-in per-project todos
- Pick any project's todos from a list, without being in that directory
- Persists across sessions (stored as JSON, never inside your projects)

## Installation

**lazy.nvim**
```lua
{
  "gunawanahmad/todo.nvim",
  config = function()
    require("todo").setup({
      keymap          = "<leader>td", -- global todo tree
      global_keymap   = "<leader>tg", -- jump to global folder
      project_keymap  = "<leader>tp", -- current project todos
      projects_keymap = "<leader>tP", -- picker across all projects
    })
  end,
}
```

All keymaps are optional — set any to `false` to disable.

## Usage

### Global keymaps

| Key / Command      | Action                                      |
|--------------------|---------------------------------------------|
| `<leader>td`       | Open todo tree                              |
| `<leader>tg`       | Open todo tree, jump to `global` folder     |
| `<leader>tp`       | Open current project's todos                |
| `<leader>tP`       | Pick any project from a list                |
| `:Todo`            | Open todo tree                              |
| `:Todo global`     | Open todo tree, jump to `global` folder     |
| `:TodoProject`     | Open current project's todos                |
| `:TodoProjects`    | Pick any project from a list                |
| `:TodoInit`        | Initialize project todos for the current repo |

### Inside the window

| Key              | Action                                      |
|------------------|---------------------------------------------|
| `<CR>` / `Space` | Expand/collapse folder · Toggle todo done   |
| `x`              | Toggle todo done                            |
| `a`              | Add todo to folder at cursor                |
| `A`              | Add new folder                              |
| `e`              | Edit todo text · Rename folder              |
| `d`              | Delete todo · Delete folder (with prompt)   |
| `D`              | Clear completed todos in current folder     |
| `q` / `Esc`      | Close                                       |

## Project todos

Project todos are **opt-in** — nothing is created automatically when you open a project.

1. Run `:TodoInit` once inside a git repo to enable project todos for it.
2. Use `<leader>tp` to open that project's todos whenever you're inside it.
3. Use `<leader>tP` (or `:TodoProjects`) from anywhere to pick any initialized project.

Project files are stored in `~/.local/share/nvim/todo/projects/` — never inside your repos.

## Data

| Location | Contents |
|---|---|
| `~/.local/share/nvim/todo.json` | Global todos |
| `~/.local/share/nvim/todo/projects/<name>.json` | Per-project todos |
