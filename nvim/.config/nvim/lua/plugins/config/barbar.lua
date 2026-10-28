-- Barbar Configuration
-- Loaded via require() from your barbar spec, same pattern as lualine

vim.g.barbar_auto_setup = false

require("barbar").setup({
	animation = false,
	clickable = true,
	tabpages = true,
	focus_on_close = "left",
	insert_at_end = true, -- new buffers open at the end instead of next to the current one
	maximum_length = 30,
	minimum_padding = 1,
	maximum_padding = 2,
	no_name_title = "[No Name]",
	exclude_ft = { "alpha", "dashboard" },
	hide = { extensions = false, inactive = false },
	icons = {
		buffer_index = false,
		buffer_number = false,
		button = "\u{f00d}", -- close button (was stripped to an empty string)
		diagnostics = {
			[vim.diagnostic.severity.ERROR] = { enabled = true, icon = "󰅚 " },
			[vim.diagnostic.severity.WARN] = { enabled = true, icon = "󰀦 " },
			[vim.diagnostic.severity.INFO] = { enabled = false },
			[vim.diagnostic.severity.HINT] = { enabled = false },
		},
		gitsigns = {
			added = { enabled = true, icon = "\u{f457}" },
			changed = { enabled = true, icon = "\u{f459}" },
			deleted = { enabled = true, icon = "\u{f458}" },
		},
		filetype = { enabled = true },
		separator = { left = "▎", right = " " },
		separator_at_end = true,
		modified = { button = "●" },
		pinned = { button = "\u{f435}", filename = true },
		current = { buffer_index = true },
		inactive = { button = "×" },
		visible = { modified = { buffer_number = false } },
	},
	sidebar_filetypes = {
		NvimTree = true,
		undotree = {
			text = "undotree",
			align = "left",
		},
	},
})

-- Keymaps (delete any that clash with yours)
local map = vim.keymap.set
local function o(desc)
	return { silent = true, desc = desc }
end

map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", o("Previous buffer"))
map("n", "<A-.>", "<Cmd>BufferNext<CR>", o("Next buffer"))
map("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", o("Move buffer left"))
map("n", "<A->>", "<Cmd>BufferMoveNext<CR>", o("Move buffer right"))
map("n", "<A-p>", "<Cmd>BufferPin<CR>", o("Pin buffer"))
map("n", "<A-c>", "<Cmd>BufferClose<CR>", o("Close buffer"))
map("n", "<A-0>", "<Cmd>BufferLast<CR>", o("Last buffer"))
for i = 1, 9 do
	map("n", "<A-" .. i .. ">", "<Cmd>BufferGoto " .. i .. "<CR>", o("Go to buffer " .. i))
end
map("n", "<leader>bp", "<Cmd>BufferPick<CR>", o("Pick buffer"))
map("n", "<leader>bd", "<Cmd>BufferPickDelete<CR>", o("Pick buffer to close"))
map("n", "<leader>bo", "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", o("Close other buffers"))
