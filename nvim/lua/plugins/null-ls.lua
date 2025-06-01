return {
  "jose-elias-alvarez/null-ls.nvim", -- original null-ls
  name = "null-ls",         -- opcional: faz :Lazy list exibir como null-ls
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    -- Temporary compatibility shim for Neovim ≥0.11:
    -- older null‑ls references vim.lsp._request_name_to_capability which was removed.
    if vim.lsp._request_name_to_capability == nil then
      vim.lsp._request_name_to_capability = setmetatable({}, {
        __index = function()
          -- return nil for any capability; null-ls will treat as "enabled"
          return nil
        end,
      })
    end
    local null_ls = require("null-ls") -- módulo correto permanece 'null-ls'

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.diagnostics.eslint,
      },
      on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = true
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ bufnr = bufnr })
          end,
        })
      end,
    })
  end,
}