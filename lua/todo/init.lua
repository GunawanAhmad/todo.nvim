local ui      = require("todo.ui")
local storage = require("todo.storage")

local M = {}

M.defaults = {
  keymap          = "<leader>td",
  global_keymap   = "<leader>tg",
  project_keymap  = "<leader>tp",
  projects_keymap = "<leader>tP",
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

  vim.api.nvim_create_user_command("TodoProject", function()
    ui.toggle({ project = true })
  end, {})

  vim.api.nvim_create_user_command("TodoProjects", function()
    ui.pick_project()
  end, {})

  vim.api.nvim_create_user_command("TodoInit", function()
    local ok, msg = storage.init_project()
    if ok then
      vim.notify("todo.nvim: initialized project todo for " .. msg, vim.log.levels.INFO)
    else
      vim.notify("todo.nvim: " .. msg, vim.log.levels.WARN)
    end
  end, {})

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

  if opts.project_keymap then
    vim.keymap.set("n", opts.project_keymap, function()
      ui.toggle({ project = true })
    end, {
      desc   = "Open project todos",
      silent = true,
    })
  end

  if opts.projects_keymap then
    vim.keymap.set("n", opts.projects_keymap, function()
      ui.pick_project()
    end, {
      desc   = "Pick a project todo",
      silent = true,
    })
  end
end

return M
