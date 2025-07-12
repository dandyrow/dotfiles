return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,

	init = function()
		-- Safely activate colourscheme
		local status_ok, _ = pcall(vim.cmd.colorscheme, "catppuccin")
		if not status_ok then
			vim.notify("colorscheme catppuccin not found!")
			return
		end
	end,

	opts = {
		dim_inactive = {
			enabled = true,
			shade = "dark",
			percentage = 0.15,
		},

		integrations = {
			blink_cmp = { style = "bordered" },
			native_lsp = {
				enabled = true,
				virtual_text = {
					errors = { "italic" },
					hints = { "italic" },
					warnings = { "italic" },
					information = { "italic" },
					ok = { "italic" },
				},
				underlines = {
					errors = { "underline" },
					hints = { "underline" },
					warnings = { "underline" },
					information = { "underline" },
					ok = { "underline" },
				},
				inlay_hints = { background = true },
			},
			which_key = true,
		},
	},
}
