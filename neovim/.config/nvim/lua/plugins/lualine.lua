return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "echasnovski/mini.icons" },
	opts = {
		options = {
			theme = "catppuccin",
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", "diff", "diagnostics" },
			lualine_c = { "filename", "filesize" },
			lualine_x = { "encoding", "fileformat", "filetype" },
			lualine_y = { "searchcount", "selectioncount", "location" },
			lualine_z = { "tabs" },
		},
	},
}
