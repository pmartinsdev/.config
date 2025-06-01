return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  config = function()
    require("persistence").setup({
      dir = vim.fn.stdpath("state") .. "/sessions/", -- Diretório para salvar as sessões
      options = { "buffers", "curdir", "tabpages", "winsize" }, -- O que salvar na sessão
    })
  end,
}