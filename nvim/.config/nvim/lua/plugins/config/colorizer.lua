require("colorizer").setup({
	filetypes = { "*" },
	user_default_options = {
		RGB = true, -- #RGB
		RRGGBB = true, -- #RRGGBB
		RRGGBBAA = true, -- #RRGGBBAA
		names = false, -- turn off "red", "blue" etc. (it's noisy in code)
		css = true, -- enables rgb(), hsl(), etc.
		tailwind = true, -- Tailwind class colors like bg-red-500
		mode = "background", -- or "foreground" / "virtualtext"
	},
})

-- Highlight bare hex colors (e.g. fuzzel's `background=282828ee`)
local ns = vim.api.nvim_create_namespace("bare_hex_colors")

local function highlight_bare_hex(buf)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for lnum, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		local s, e, hex = line:find("=(%x%x%x%x%x%x)%x?%x?%s*$")
		if s then
			local group = "BareHex_" .. hex
			local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
			local fg = (r * 299 + g * 587 + b * 114) / 1000 > 128 and "#000000" or "#ffffff"
			vim.api.nvim_set_hl(0, group, { bg = "#" .. hex, fg = fg })
			-- highlight just the color value
			local start_col = line:find(hex, s, true) - 1
			local end_col = e - (line:match("%s*$") or ""):len()
			vim.api.nvim_buf_add_highlight(buf, ns, group, lnum - 1, start_col, end_col)
		end
	end
end

vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
	pattern = { "*.ini", "*.conf" },
	callback = function(args)
		highlight_bare_hex(args.buf)
	end,
})
