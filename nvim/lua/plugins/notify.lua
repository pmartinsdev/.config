return {
  "rcarriga/nvim-notify",
  lazy = false,
  config = function()
    local notify = require("notify")
    vim.notify = notify

    -- Configuração opcional
    notify.setup({
      stages = "fade_in_slide_out", -- Estilo de animação
      timeout = 3000,              -- Tempo de exibição (em ms)
      background_colour = "#000000",
    })
  end,
}
