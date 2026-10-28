-- Loaded via require("plugins.config.lualine") from your lualine spec (VeryLazy)

-- Localize frequent API calls
local fn = vim.fn
local api = vim.api

local function refresh()
	pcall(function()
		require("lualine").refresh()
	end)
end

-- Auto-save state lives in an upvalue, not _G
local autosave_status = ""
local autosave_token = 0

local save_group = api.nvim_create_augroup("LualineAutoSave", { clear = true })
api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave" }, {
	group = save_group,
	callback = function(args)
		local b = vim.bo[args.buf]
		if b.modified and b.buftype == "" and api.nvim_buf_get_name(args.buf) ~= "" then
			api.nvim_buf_call(args.buf, function()
				vim.cmd("silent! update")
			end)
			autosave_status = "󰄬 SAVED"
			autosave_token = autosave_token + 1
			local my_token = autosave_token
			refresh()
			vim.defer_fn(function()
				-- Only clear if no newer save happened meanwhile
				if my_token == autosave_token then
					autosave_status = ""
					refresh()
				end
			end, 800)
		end
	end,
})

-- File size cached per buffer (no stat call on every redraw)
local function update_size(args)
	local file = api.nvim_buf_get_name(args.buf)
	local size = file ~= "" and fn.getfsize(file) or -1
	if size <= 0 then
		vim.b[args.buf].file_size_str = ""
		return
	end
	local suffixes = { "B", "KB", "MB", "GB" }
	local i = 1
	while size >= 1024 and i < #suffixes do
		size = size / 1024
		i = i + 1
	end
	vim.b[args.buf].file_size_str = string.format("%.1f%s", size, suffixes[i])
end

api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
	group = api.nvim_create_augroup("LualineFileSize", { clear = true }),
	callback = update_size,
})
-- VeryLazy runs after the first buffer is already entered, so fill it in now
update_size({ buf = api.nvim_get_current_buf() })

-- Macro recording indicator updates immediately
api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
	group = api.nvim_create_augroup("LualineRecording", { clear = true }),
	callback = function()
		vim.schedule(refresh)
	end,
})

require("lualine").setup({
	options = {
		icons_enabled = true,
		-- theme = "auto", -- Uses compiled highlights if Catppuccin compile is enabled
		component_separators = { left = "\u{e0b5}", right = "\u{e0b7}" },
		section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" },
		disabled_filetypes = {
			-- Fully hide only on start screens
			statusline = { "alpha", "dashboard" },
		},
		-- With globalstatus, these keep showing the last real window's info
		ignore_focus = { "NvimTree", "toggleterm", "qf", "help", "lazy", "mason", "oil" },
		always_divide_middle = true,
		globalstatus = true,
	},
	sections = {
		lualine_a = {
			{
				"mode",
				fmt = function(str)
					return "\u{e7c5} " .. str
				end,
			},
		},
		lualine_b = {
			{
				"branch",
				icon = "󰘬",
				fmt = function(str)
					return #str > 15 and (string.sub(str, 1, 12) .. "...") or str
				end,
			},
			{
				"diff",
				colored = true,
				symbols = { added = "\u{f457} ", modified = "\u{f459} ", removed = "\u{f458} " },
			},
		},
		lualine_c = {
			{
				"filename",
				path = 1,
				file_status = true,
				symbols = { modified = " 󰏫", readonly = " \u{f023}" },
			},
			{
				function()
					local reg = fn.reg_recording()
					return reg ~= "" and ("󰑋 REC @" .. reg) or ""
				end,
				color = { gui = "bold" },
			},
		},
		lualine_x = {
			{
				function()
					return autosave_status
				end,
				color = { gui = "bold" },
			},
			{
				function()
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					if #clients == 0 then
						return ""
					end
					local names = {}
					for _, c in ipairs(clients) do
						table.insert(names, c.name)
					end
					return "󰒋 " .. table.concat(names, ", ")
				end,
			},
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				sections = { "error", "warn" },
				symbols = { error = "󰅚 ", warn = "󰀦 " },
				colored = true,
				update_in_insert = true,
				always_visible = false,
				cond = function()
					return vim.bo.filetype ~= "markdown"
				end,
			},
			{
				function()
					return vim.b.file_size_str or ""
				end,
			},
			"filetype",
		},
		lualine_y = {
			{
				function()
					local curr = fn.line(".")
					local total = fn.line("$")
					if total == 0 then
						return "0%%"
					end
					local chars = { " ", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
					local ratio = curr / total
					local idx = math.max(1, math.min(#chars, math.ceil(ratio * #chars)))
					return chars[idx] .. " " .. math.floor(ratio * 100) .. "%%"
				end,
			},
		},
		lualine_z = {
			{
				"location",
				icon = "󰍎",
			},
		},
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { { "filename", path = 1 } },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
})
