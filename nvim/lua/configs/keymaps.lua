vim.g.mapleader = " "

local map = vim.keymap.set

vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

-- Telescope key mappings
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")

-- Nvim-tree key mappings
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", { noremap = true, silent = true })

-- Telescope file browser with filtering
map("n", "<leader>fe", "<cmd>Telescope file_browser<cr>")

-- Renomear símbolo e atualizar referências
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")

-- Renomear arquivo e atualizar importações
map("n", "<leader>rf", "<cmd>TypescriptRenameFile<CR>")

-- Abrir Lazygit
map("n", "<leader>gg", "<cmd>LazyGit<CR>", { noremap = true, silent = true })

-- Comment toggle
vim.keymap.set("n", "<leader>/", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", { noremap = true, silent = true })

-- Gitsigns key mappings
vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gd", "<cmd>Gitsigns diffthis<CR>", { noremap = true, silent = true })

-- LSP and diagnostics key mappings
vim.keymap.set("n", "<leader>fm", "<cmd>lua vim.lsp.buf.format()<CR>", { noremap = true, silent = true })

-- Navigate diagnostics with Ctrl+j and Ctrl+k
vim.keymap.set("n", "<C-j>", "<cmd>lua vim.diagnostic.goto_next()<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { noremap = true, silent = true })

