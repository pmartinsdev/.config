return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_c, 1, {
        function()
          return require("workspace.worktrees").statusline()
        end,
        cond = function()
          return require("workspace.worktrees").statusline() ~= ""
        end,
        color = "DiagnosticInfo",
      })
    end,
  },
}
