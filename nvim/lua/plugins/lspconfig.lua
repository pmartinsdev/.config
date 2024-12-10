return {
	"neovim/nvim-lspconfig",
	config = function()
		local lspconfig = require("lspconfig")

		vim.diagnostic.config({
			virtual_text = {
				prefix = "●", -- Change prefix if desired
			},
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		-- Define diagnostic signs for the gutter
		vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError" })
		vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn" })
		vim.fn.sign_define("DiagnosticSignInfo", { text = "", texthl = "DiagnosticSignInfo" })
		vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })

		-- TSServer setup
		lspconfig.tsserver.setup({
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false

				local opts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "<C-k>", vim.diagnostic.goto_prev, opts)
				vim.keymap.set("n", "<C-j>", vim.diagnostic.goto_next, opts)
				vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
				vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
			end,
			flags = {
				debounce_text_changes = 150,
			},
		})

		-- ESLint setup
		lspconfig.eslint.setup({
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = true -- Enable ESLint formatting

				-- Format on save
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({ bufnr = bufnr })
					end,
				})

				local opts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
			end,
		})
	end,
}
