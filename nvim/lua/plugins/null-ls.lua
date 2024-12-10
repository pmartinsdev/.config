return {
	"jose-elias-alvarez/null-ls.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				-- ESLint for diagnostics and code actions
				null_ls.builtins.diagnostics.eslint_d,
				null_ls.builtins.code_actions.eslint_d,
			},
			on_attach = function(client, bufnr)
				-- Format on save
				if client.supports_method("textDocument/formatting") then
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ bufnr = bufnr })
						end,
					})
				end
			end,
		})
	end,
}
