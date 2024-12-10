return {
	{ "nvim-treesitter/playground", cmd = "TSPlaygroundToggle" },
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"css",
				"fish",
				"gitignore",
				"graphql",
				"http",
				"php",
				"rust",
				"scss",
				"sql",
				"yaml",
				"angular",
				"lua",
				"html",
				"tsx",
				"javascript",
				"typescript", -- Added TypeScript
				"json", -- Added JSON
				"bash", -- Added Bash
				"markdown", -- Added Markdown
				"markdown_inline", -- Inline Markdown
			},

			matchup = {
				enable = true, -- Enable Matchup
			},

			query_linter = {
				enable = true,
				use_virtual_text = true,
				lint_events = { "BufWrite", "CursorHold" },
			},

			playground = {
				enable = true,
				disable = {},
				updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
				persist_queries = true, -- Whether the query persists across vim sessions
				keybindings = {
					toggle_query_editor = "o",
					toggle_hl_groups = "i",
					toggle_injected_languages = "t",
					toggle_anonymous_nodes = "a",
					toggle_language_display = "I",
					focus_language = "f",
					unfocus_language = "F",
					update = "R",
					goto_node = "<cr>",
					show_help = "?",
				},
			},

			highlight = {
				enable = true,
				disable = function(_, buf)
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)

			-- MDX
			vim.filetype.add({
				extension = {
					mdx = "mdx",
				},
			})
			vim.treesitter.language.register("markdown", "mdx")
		end,
	},
}
