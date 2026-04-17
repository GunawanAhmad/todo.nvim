local ui = require("todo.ui")

local M = {}

M.defaults = {
  keymap = "<leader>td",
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})

  vim.api.nvim_create_user_command("Todo", function() ui.toggle() end, {})

  if opts.keymap then
    vim.keymap.set("n", opts.keymap, ui.toggle, {
      desc    = "Toggle todo list",
      silent  = true,
    })
  end
end

return M
