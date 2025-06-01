local typescript = require("typescript")
local lspconfig = require("lspconfig")

typescript.setup({
  server = {
    on_attach = function(client, bufnr)
      local buf_map = vim.api.nvim_buf_set_keymap
      buf_map(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { noremap = true, silent = true })
      buf_map(bufnr, "n", "<leader>rf", "<cmd>TypescriptRenameFile<CR>", { noremap = true, silent = true })
    end,
  },
})

lspconfig.tsserver.setup({
  on_attach = function(client, bufnr)
    local buf_map = vim.api.nvim_buf_set_keymap
    local opts = { noremap = true, silent = true }

    buf_map(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    buf_map(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
    buf_map(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  end,
})