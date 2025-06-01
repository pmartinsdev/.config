return {
	{
		"hrsh7th/nvim-cmp",
		lazy = false,
		priority = 1000,
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
				}),
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local lspconfig = require("lspconfig")
			-- Define capacidades manualmente sem cmp-nvim-lsp
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.textDocument.completion.completionItem.snippetSupport = true

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
					-- Habilitar recursos explicitamente
					client.server_capabilities.documentFormattingProvider = true
					client.server_capabilities.documentRangeFormattingProvider = true

					-- Format-on-save com filtro específico
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({
								async = false,
								filter = function(c)
									return c.name == "eslint"
								end,
							})
						end,
					})

					-- Mapeamentos padrão
					common_on_attach(client, bufnr)
				end,
				capabilities = capabilities,
				settings = {
					eslint = {
						format = {
							enable = true,
						},
						validate = "on",
						packageManager = "npm",
						workingDirectory = {
							mode = "auto",
						},
					},
				},
				root_dir = require("lspconfig.util").root_pattern(
					".eslintrc",
					".eslintrc.js",
					".eslintrc.cjs",
					".eslintrc.yaml",
					".eslintrc.yml",
					".eslintrc.json",
					"package.json"
				),
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
				filetypes = {
					"html",
					"css",
					"scss",
					"javascript",
					"javascriptreact",
					"typescriptreact",
					"vue",
					"svelte",
				},
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
	},
}
