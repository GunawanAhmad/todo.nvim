# todo.nvim

A simple, persistent todo list for Neovim — accessible from anywhere via a floating window.

## Features

- Floating window accessible from any buffer
- Todos persist across sessions (stored as JSON)
- Mark items done, edit, or delete inline

## Installation

**lazy.nvim**
```lua
{
  "gunawanahmad/todo.nvim",
  config = function()
    require("todo").setup({
      keymap = "<leader>td", -- default
    })
  end,
}
```

## Usage

| Key / Command    | Action              |
|------------------|---------------------|
| `<leader>td`     | Toggle todo window  |
| `:Todo`          | Toggle todo window  |

**Inside the window:**

| Key        | Action                  |
|------------|-------------------------|
| `a`        | Add new todo            |
| `e`        | Edit todo under cursor  |
| `<CR>` / `x` | Toggle done           |
| `d`        | Delete todo             |
| `D`        | Clear all completed     |
| `q` / `<Esc>` | Close window         |

## Data

Todos are saved to `~/.local/share/nvim/todo.json`.
