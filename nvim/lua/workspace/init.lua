local M = {}

function M.setup()
  local root = require("workspace.root")
  local follow = require("workspace.follow")
  local worktrees = require("workspace.worktrees")

  root.refresh()
  follow.setup()
  worktrees.setup()

  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("workspace", { clear = true }),
    callback = function()
      root.refresh()
      follow.watch()
      worktrees.refresh_label()
    end,
  })
end

return M
