vim.opt.relativenumber = true -- Habilitar linhas relativas
vim.opt.number = true         -- Mostrar o número da linha atual

-- Garantir que Ctrl+i e Ctrl+o funcionem para navegação no histórico de saltos
vim.keymap.set("n", "<C-o>", "<C-o>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-i>", "<C-i>", { noremap = true, silent = true })

-- Neotree key mapping
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { noremap = true, silent = true })