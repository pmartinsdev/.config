return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			size = 20,
			open_mapping = [[<C-\>]], -- Default keybinding to toggle terminal
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			persist_size = true,
			direction = "float", -- Set terminal to open in floating mode
			close_on_exit = true,
			shell = vim.o.shell,
			float_opts = {
				border = "curved", -- Border style: single, double, shadow, or curved
				width = math.floor(vim.o.columns * 0.8),
				height = math.floor(vim.o.lines * 0.8),
			},
		})

		-- Optional: Custom keybinding for floating terminal
		vim.api.nvim_set_keymap(
			"n",
			"<leader>ft",
			"<Cmd>ToggleTerm direction=float<CR>",
			{ noremap = true, silent = true }
		)
	end,
}
