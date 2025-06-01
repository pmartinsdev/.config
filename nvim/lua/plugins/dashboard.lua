return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/persistence.nvim" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    dashboard.section.header.val = {
      "██████╗ ███╗   ███╗ █████╗ ██████╗ ████████╗██╗███╗   ██╗███████╗██████╗ ███████╗██╗   ██╗",
      "██╔══██╗████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝██║████╗  ██║██╔════╝██╔══██╗██╔════╝██║   ██║",
      "██████╔╝██╔████╔██║███████║██████╔╝   ██║   ██║██╔██╗ ██║███████╗██║  ██║█████╗  ██║   ██║",
      "██╔═══╝ ██║╚██╔╝██║██╔══██║██╔══██╗   ██║   ██║██║╚██╗██║╚════██║██║  ██║██╔══╝  ╚██╗ ██╔╝",
      "██║     ██║ ╚═╝ ██║██║  ██║██║  ██║   ██║   ██║██║ ╚████║███████║██████╔╝███████╗ ╚████╔╝ ",
      "╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚══════╝╚═════╝ ╚══════╝  ╚═══╝  ",
    }
    dashboard.section.header.opts = {
      position = "center",
    }

    dashboard.section.buttons.val = {
      dashboard.button("f", "  Procurar por arquivo", ":Telescope find_files<CR>"),
      dashboard.button("n", "  Novo Arquivo", ":ene <BAR> startinsert <CR>"),
      dashboard.button("r", "  Arquivos Recentes", ":Telescope oldfiles<CR>"),
      dashboard.button("g", "  Procurar por Texto", ":Telescope live_grep<CR>"),
      dashboard.button("s", "  Restaurar Sessão", ":lua require('persistence').load()<CR>"),
      dashboard.button("c", "  Configurações", ":e ~/.config/nvim/init.lua<CR>"),
      dashboard.button("q", "  Sair", ":qa<CR>"),
    }
    dashboard.section.buttons.opts = {
      position = "center",
    }

    dashboard.section.footer.val = {
      "Happy Hacking !!!",
    }
    dashboard.section.footer.opts = {
      position = "center",
    }

    dashboard.config.layout = {
      { type = "padding", val = 5 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      { type = "padding", val = 2 },
      dashboard.section.footer,
    }

    alpha.setup(dashboard.config)

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.fn.argc() == 0 and vim.bo.filetype == "" then
          require("alpha").start()
        end
      end,
    })

    vim.cmd([[
        highlight AlphaHeader guibg=NONE
        highlight AlphaButtons guibg=NONE
        highlight AlphaFooter guibg=NONE
    ]])
  end,
}