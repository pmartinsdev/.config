local lspconfig = require("lspconfig")

local function on_attach(client, bufnr)
  local buf_map = vim.api.nvim_buf_set_keymap
  local opts = { noremap = true, silent = true }

  -- Atalhos LSP
  buf_map(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  buf_map(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  buf_map(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
end

-- Lista de servidores LSP
local servers = { "pyright", "gopls", "jsonls", "yamlls" }

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    on_attach = on_attach,
  })
end