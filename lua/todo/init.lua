local ui = require("todo.ui")

local M = {}

M.defaults = {
  keymap        = "<leader>td",
  global_keymap = "<leader>tg",
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})

  vim.api.nvim_create_user_command("Todo", function(args)
    if args.args == "global" then
      ui.toggle({ focus_folder = "global" })
    else
      ui.toggle()
    end
  end, { nargs = "?" })

  if opts.keymap then
    vim.keymap.set("n", opts.keymap, function() ui.toggle() end, {
      desc   = "Toggle todo list",
      silent = true,
    })
  end

  if opts.global_keymap then
    vim.keymap.set("n", opts.global_keymap, function()
      ui.toggle({ focus_folder = "global" })
    end, {
      desc   = "Open global todos",
      silent = true,
    })
  end
end

return M
