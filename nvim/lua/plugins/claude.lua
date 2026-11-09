return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal_cmd = require("workspace.sessions").claude_bin(),
      focus_after_send = true,
      terminal = {
        provider = require("workspace.claude_terminals"),
        split_side = "right",
        split_width_percentage = 0.38,
        snacks_win_opts = {
          wo = { winbar = "%#Comment# Ctrl+q modo normal │ Ctrl+h código │ Ctrl+/ esconder ou abrir" },
          keys = {
            claude_normal_mode = {
              "<C-q>",
              function()
                vim.cmd("stopinsert")
              end,
              mode = "t",
              desc = "Normal mode",
            },
            nav_j = false,
            nav_k = false,
            nav_l = false,
          },
        },
      },
    },
    keys = {
      {
        "<leader>aq",
        function()
          require("claude.ask").ask_here()
        end,
        desc = "Ask Claude about this code",
      },
      {
        "<leader>aq",
        function()
          require("claude.ask").ask_selection()
        end,
        mode = "x",
        desc = "Ask Claude about selection",
      },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ax", "<cmd>ClaudeCodeCloseAllDiffs<cr>", desc = "Close all Claude diffs" },
    },
  },
}
