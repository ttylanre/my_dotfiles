-- lua/plugins/ui.lua
return {
	-- Active Colorscheme (Must load early)
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		priority = 1000,
		build = ":CatppuccinCompile",
		opts = {
			flavour = "mocha",
		},
		config = function()
			require("plugins.config.colorscheme")
		end,
	},

	-- Inactive Colorschemes (Lazy load)
	{
		"ellisonleao/gruvbox.nvim",
		lazy = true,
		opts = {
			terminal_colors = true,
			undercurl = true,
			underline = true,
			bold = true,
			italic = {
				strings = true,
				emphasis = true,
				comments = true,
				operators = false,
				folds = true,
			},
		},
	},
	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		config = function()
			vim.schedule(function()
				require("plugins.config.lualine")
			end)
		end,
	},

	-- Bufferline
	{
		"romgrk/barbar.nvim",
		event = "BufReadPre",
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		config = function()
			require("plugins.config.barbar")
		end,
	},

	-- 	Interactive breadcrumb/navigation bar
	{
		"Bekaboo/dropbar.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {},
		keys = {
			{
				"<leader>;",
				function()
					require("dropbar.api").pick()
				end,
				desc = "Dropbar: Pick symbol",
			},
			{
				"[;",
				function()
					require("dropbar.api").goto_context_start()
				end,
				desc = "Dropbar: Previous context",
			},
			{
				"];",
				function()
					require("dropbar.api").select_next_context()
				end,
				desc = "Dropbar: Next context",
			},
		},
	},

	-- Startup dashboard
	--[[ {
		"goolord/alpha-nvim",
		event = "VimEnter",
		config = function()
			require("plugins.config.alpha")
		end,
	}, ]]

	-- Which-key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			require("plugins.config.which-key")
		end,
	},

	-- Focus dimming
	--[[ {
		"folke/twilight.nvim",
		cmd = "Twilight",
		keys = {
			{ "<leader>lt", "<cmd>Twilight<CR>", desc = "Toggle Twilight" },
		},
		config = function()
			require("plugins.config.twilight")
		end,
	}, ]]

	-- Icons
	{
		"echasnovski/mini.icons",
		lazy = true,
		opts = {},
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},

	{
		"kevinhwang91/nvim-ufo",
		dependencies = "kevinhwang91/promise-async",
		event = "BufReadPost",
		keys = {
			{
				"zO",
				function()
					require("ufo").openAllFolds()
				end,
				desc = "Open all folds",
			},
			{
				"zC",
				function()
					require("ufo").closeAllFolds()
				end,
				desc = "Close all folds",
			},
			{
				"zP",
				function()
					local winid = require("ufo").peekFoldedLinesUnderCursor()
					if not winid then
						vim.lsp.buf.hover()
					end
				end,
				desc = "Peek Fold / Hover",
			},
		},
		config = function()
			vim.o.foldcolumn = "1"
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true

			require("ufo").setup({
				provider_selector = function(bufnr, filetype, buftype)
					local disabled_fts = { "neo-tree", "NvimTree", "alpha", "dashboard", "toggleterm" }
					if vim.tbl_contains(disabled_fts, filetype) or buftype ~= "" then
						return ""
					end
					return { "treesitter", "indent" }
				end,
			})
		end,
	},
	-- Fun
	--[[ {
		"eandrju/cellular-automaton.nvim",
		cmd = "CellularAutomaton",
	},]]
}
