return {
	{
		"stevearc/oil.nvim",
		dependencies = { "echasnovski/mini.icons" },
		opts = {
			columns = {
				"icon",
				"permissions",
				"size",
				"mtime",
			},
			view_options = {
				show_hidden = true,
			},
			win_options = {
				signcolumn = "yes:2",
			},
		},
		lazy = false,
		keys = {
			{
				"<leader>a",
				"<CMD>Oil<CR>",
				desc = "Open Oil in current file's directory",
			},
		},
	},
	{
		"benomahony/oil-git.nvim",
		dependencies = { "stevearc/oil.nvim" },
		opts = true,
	},
}
