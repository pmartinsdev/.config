local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Select all file text
keymap.set("n", "<C-a>", "gg<S-v>G", opts)

-- Tabs
keymap.set("n", "te", ":tabedit ", opts)
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Todo's
keymap.set("n", "<leader>t", ":OpenTodos<Return>GA", opts)
