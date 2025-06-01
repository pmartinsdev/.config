return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "jose-elias-alvarez/typescript.nvim",
    require("plugins.lazygit"),
  },
  config = function()
    require("plugins.lsp.mason")
    require("plugins.lsp.typescript")
    require("plugins.lsp.general")

  local lspconfig = require("lspconfig")

    lspconfig.eslint.setup({
      on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = true
        client.server_capabilities.documentRangeFormattingProvider = true
      end,
    })
  end,
}