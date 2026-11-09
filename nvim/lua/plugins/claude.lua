local claude_bin = vim.fn.exepath("claude")
if claude_bin == "" then
  claude_bin = vim.fn.expand("~/.local/bin/claude")
end
local nvim_settings = vim.fn.stdpath("config") .. "/claude/settings.json"

return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal_cmd = ("%s --settings %s"):format(claude_bin, vim.fn.shellescape(nvim_settings)),
      focus_after_send = true,
      terminal = {
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
      {
        "<leader>aw",
        function()
          require("claude.follow").toggle()
        end,
        desc = "Toggle following Claude edits",
      },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ax", "<cmd>ClaudeCodeCloseAllDiffs<cr>", desc = "Close all Claude diffs" },
    },
  },
}
