return {
	"neovim/nvim-lspconfig",
	config = function()
		local lspconfig = require("lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_nvim_lsp.default_capabilities()

		vim.diagnostic.config({
			virtual_text = { prefix = "●" },
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError" })
		vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn" })
		vim.fn.sign_define("DiagnosticSignInfo", { text = "", texthl = "DiagnosticSignInfo" })
		vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })

		local common_on_attach = function(client, bufnr)
			local opts = { noremap = true, silent = true, buffer = bufnr }
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
			vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "<C-k>", vim.diagnostic.goto_prev, opts)
			vim.keymap.set("n", "<C-j>", vim.diagnostic.goto_next, opts)
		end

		lspconfig.tsserver.setup({
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
				common_on_attach(client, bufnr)
			end,
			capabilities = capabilities,
			flags = { debounce_text_changes = 150 },
			root_dir = function(...)
				return require("lspconfig.util").root_pattern(".git")(...)
			end,
			settings = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "literal",
						includeInlayFunctionParameterTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
				},
				javascript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
				},
			},
		})

		lspconfig.eslint.setup({
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = true
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({ bufnr = bufnr })
					end,
				})
				common_on_attach(client, bufnr)
			end,
		})

		lspconfig.lua_ls.setup({
			on_attach = common_on_attach,
			capabilities = capabilities,
			settings = {
				Lua = {
					workspace = { checkThirdParty = false },
					completion = { workspaceWord = true, callSnippet = "Both" },
					hint = { enable = true, setType = false, paramType = true },
					diagnostics = {
						disable = { "incomplete-signature-doc", "trailing-space" },
						groupSeverity = { strong = "Warning", strict = "Warning" },
						unusedLocalExclude = { "_*" },
					},
					format = {
						enable = false,
						defaultConfig = {
							indent_style = "space",
							indent_size = "2",
							continuation_indent_size = "2",
						},
					},
				},
			},
		})

		lspconfig.yamlls.setup({
			on_attach = common_on_attach,
			capabilities = capabilities,
			settings = { yaml = { keyOrdering = false } },
		})

		lspconfig.tailwindcss.setup({
			on_attach = common_on_attach,
			capabilities = capabilities,
			filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescriptreact", "vue", "svelte" },
			settings = {
				tailwindCSS = {
					experimental = {
						classRegex = {
							"tw`([^`]*)",
							'tw\\("([^"]*)',
							"tw\\('([^']*)",
						},
					},
				},
			},
		})

		local util = require("lspconfig.util")
		local function get_probe_dir(root_dir)
			local node_modules = vim.fs.find("node_modules", { path = root_dir, upward = true })
			if node_modules and #node_modules > 0 then
				return vim.fs.dirname(node_modules[1]) .. "/node_modules"
			end
			return ""
		end

		lspconfig.angularls.setup({
			on_attach = common_on_attach,
			capabilities = capabilities,
			cmd = {
				"ngserver",
				"--stdio",
				"--tsProbeLocations",
				get_probe_dir(vim.fn.getcwd()),
				"--ngProbeLocations",
				get_probe_dir(vim.fn.getcwd()),
				"--includeCompletionsWithSnippetText",
				"--includeAutomaticOptionalChainCompletions",
			},
			filetypes = { "html", "typescript", "typescriptreact", "typescript.tsx", "htmlangular" },
			root_dir = util.root_pattern("angular.json", ".git"),
		})
	end,
	dependencies = {
		{ "folke/neoconf.nvim", cmd = "Neoconf", config = false },
		{ "folke/lazydev.nvim", opts = {} },
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
}
