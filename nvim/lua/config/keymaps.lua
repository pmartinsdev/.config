-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function toggle_claude()
  require("lazy").load({ plugins = { "claudecode.nvim" } })
  vim.cmd("ClaudeCode")
end

vim.keymap.set({ "n", "t" }, "<C-/>", toggle_claude, { desc = "Toggle Claude" })
vim.keymap.set({ "n", "t" }, "<C-_>", toggle_claude, { desc = "which_key_ignore" })

vim.keymap.set("n", "<leader>aw", function()
  require("workspace.follow").toggle()
end, { desc = "Toggle following worktree changes" })
