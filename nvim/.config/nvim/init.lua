-- Lanre's Neovim Config
-- Initially Bread's but This Neovim configuration has grown on me 😅😅😅😅
-- Fast, modular, and IDE-level features

-- Performance tracking
vim.g.start_time = vim.fn.reltime()
vim.loader.enable() -- SPEED

-- Leader key setup (BEFORE lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Load core options and mappings
require("config.options")
require("config.autocmd")
require("config.mappings")

-- Initialize lazy.nvim with specs from lua/plugins/
require("lazy").setup("plugins", {
	defaults = {
		lazy = true, -- Default to lazy loading
		version = false, -- Use latest version by default
	},
	install = {
		missing = true,
		colorscheme = { "catppuccin" },
	},
	change_detection = {
		enabled = true,
		notify = false, -- Disabled to avoid eager notify execution on file changes
	},
	performance = {
		rtp = {
			disabled_plugins = {
				"2html_plugin",
				"bugreport",
				"compiler",
				"editorconfig",
				"getscript",
				"getscriptPlugin",
				"gzip",
				"logipat",
				"man",
				"matchit",
				"matchparen",
				"net",
				"netrw",
				"netrwFileHandlers",
				"netrwPlugin",
				"netrwSettings",
				"optwin",
				"osc52",
				"rplugin",
				"rrhelper",
				"shada",
				"spellfile",
				"spellfile_plugin",
				"synmenu",
				"tar",
				"tarPlugin",
				"tohtml",
				"tutor",
				"vimball",
				"vimballPlugin",
				"zip",
				"zipPlugin",
			},
		},
	},
	ui = {
		icons = {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			favorite = "⭐",
			ft = "📂",
			init = "⚙",
			keys = "🔑",
			lazy = "💤",
			loaded = "✓",
			not_loaded = "✗",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			list = {
				"●",
				"➜",
				"★",
				"‣",
			},
		},
	},
})

-- Load theme synchronously AFTER lazy setup
require("config.theme")
if type(load_theme) == "function" then
	load_theme()
else
	vim.cmd.colorscheme("catppuccin")
end

-- Display startup time using native print (avoids triggering nvim-notify)
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local time = vim.fn.reltimestr(vim.fn.reltime(vim.g.start_time))
		vim.g.startup_time = time
		-- Uncomment to print startup time without triggering nvim-notify:
		print("Neovim startup time: " .. time .. "ms")
	end,
})
