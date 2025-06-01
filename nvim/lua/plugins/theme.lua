return {
  "folke/tokyonight.nvim",
  config = function()
    -- Configurar o tema Tokyonight
    require("tokyonight").setup({
      style = "night", -- Estilo do tema: night, storm, day, moon
      transparent = true, -- Habilitar fundo transparente
      terminal_colors = true, -- Usar cores do tema no terminal integrado
    })

    -- Aplicar o esquema de cores
    vim.cmd([[colorscheme tokyonight]])

    -- Ajustar transparência para outros elementos
    vim.cmd([[
      highlight Normal guibg=NONE ctermbg=NONE
      highlight NormalNC guibg=NONE ctermbg=NONE
      highlight LineNr guibg=NONE ctermbg=NONE
      highlight SignColumn guibg=NONE ctermbg=NONE
      highlight EndOfBuffer guibg=NONE ctermbg=NONE
    ]])
  end,
}