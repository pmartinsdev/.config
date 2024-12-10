return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		"nvim-telescope/telescope-file-browser.nvim",
	},
	keys = {
		{
			"<leader>fP",
			function()
				require("telescope.builtin").find_files({
					cwd = require("lazy.core.config").options.root,
				})
			end,
			desc = "Find Plugin File",
		},
		{
			"<leader>f",
			function()
				local builtin = require("telescope.builtin")
				builtin.find_files({
					no_ignore = false,
					hidden = true,
				})
			end,
			desc = "Lists files in your current working directory, respects .gitignore",
		},
		{
			"<leader>/",
			function()
				local builtin = require("telescope.builtin")
				builtin.live_grep()
			end,
			desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore",
		},
		{
			"\\\\",
			function()
				local builtin = require("telescope.builtin")
				builtin.buffers()
			end,
			desc = "Lists open buffers",
		},
		{
			";;",
			function()
				local builtin = require("telescope.builtin")
				builtin.resume()
			end,
			desc = "Resume the previous telescope picker",
		},
		{
			";e",
			function()
				local builtin = require("telescope.builtin")
				builtin.diagnostics()
			end,
			desc = "Lists Diagnostics for all open buffers or a specific buffer",
		},
		{
			";s",
			function()
				local builtin = require("telescope.builtin")
				builtin.treesitter()
			end,
			desc = "Lists Function names, variables, from Treesitter",
		},
		{
			"sf",
			function()
				local telescope = require("telescope")

				local function telescope_buffer_dir()
					return vim.fn.expand("%:p:h")
				end

				telescope.extensions.file_browser.file_browser({
					path = "%:p:h",
					cwd = telescope_buffer_dir(),
					respect_gitignore = false,
					hidden = true,
					grouped = true,
					previewer = false,
					initial_mode = "normal",
					layout_config = { height = 40 },
				})
			end,
			desc = "Open File Browser with the path of the current buffer",
		},
		{
			";t",
			function()
				require("telescope.builtin").buffers({
					prompt_title = "Open Terminals",
					only_cwd = true,
					ignore_current_buffer = true,
					sort_mru = true,
					filter = function(bufnr)
						local bufname = vim.api.nvim_buf_get_name(bufnr)
						return vim.bo[bufnr].buftype == "terminal" and bufname ~= ""
					end,
				})
			end,
			desc = "List Open Terminals",
		},
	},
	config = function(_, opts)
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local fb_actions = require("telescope").extensions.file_browser.actions

		opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
			wrap_results = true,
			layout_strategy = "horizontal",
			layout_config = { prompt_position = "top" },
			sorting_strategy = "ascending",
			winblend = 0,
			mappings = {
				n = {},
			},
		})
		opts.pickers = {
			diagnostics = {
				theme = "ivy",
				initial_mode = "normal",
				layout_config = {
					preview_cutoff = 9999,
				},
			},
		}
		opts.extensions = {
			file_browser = {
				theme = "dropdown",
				hijack_netrw = true,
				mappings = {
					["n"] = {
						["N"] = fb_actions.create,
						["h"] = fb_actions.goto_parent_dir,
						["/"] = function()
							vim.cmd("startinsert")
						end,
					},
				},
			},
		}

		-- Setup telescope with options
		telescope.setup(opts)
	end,

	init = function()
		local telescope = require("telescope")
		telescope.load_extension("fzf")
		telescope.load_extension("file_browser")
	end,
}
