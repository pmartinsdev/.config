return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require("gitsigns").setup({
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      current_line_blame = true, -- Habilitar blame na linha atual
      current_line_blame_opts = {
        delay = 1000, -- Tempo de atraso para exibir o blame (em ms)
        virt_text = true,
        virt_text_pos = "eol", -- Mostrar no final da linha
      },
    })
  end,
}