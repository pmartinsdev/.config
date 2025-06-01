return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
  
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<Esc>"] = actions.close,
            },
          },
          file_ignore_patterns = { "node_modules", ".git/" },
        },
        extensions = {
          file_browser = {
            hijack_netrw = true,
            mappings = {
              ["i"] = {
                -- Adicione atalhos personalizados aqui, se necessário
              },
              ["n"] = {
                -- Adicione atalhos personalizados aqui, se necessário
              },
            },
          },
        },
      })
  
      telescope.load_extension("file_browser")
    end,
  }