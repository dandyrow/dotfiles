return {
	"folke/snacks.nvim",
	dependencies = { "echasnovski/mini.icons" },
	lazy = false,
	priority = 1000,
  init = function()
    vim.o.statuscolumn = " "
  end,

	opts = {
		dashboard = {
			preset = {
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('smart')" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('live_grep', { hidden = true })",
					},
					{
						icon = " ",
						key = "r",
						desc = "Recent Files",
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = " ",
						key = "b",
						desc = "Browse Repo",
						action = function()
							Snacks.gitbrowse()
						end,
						enabled = function()
							return Snacks.git.get_root() ~= nil
						end,
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
					},
					{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
					{
						icon = "󰒲 ",
						key = "L",
						desc = "Lazy",
						action = ":Lazy",
						enabled = package.loaded.lazy ~= nil,
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
			sections = {
				{ section = "header" },
				{ section = "keys", gap = 1, padding = 1 },
				{ section = "recent_files", pane = 2, icon = " ", title = "Recent Files", indent = 2, padding = 1 },
				{ section = "projects", pane = 2, icon = " ", title = "Projects", indent = 2, padding = 1 },
				{ section = "startup" },
			},
		},

		indent = {
			indent = { char = "▏" },
			scope = { underline = true, char = "▏" },
		},

		notifier = { style = "fancy" },

		picker = {
			win = {
				input = {
					keys = {
						["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
						["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
					},
				},
			},
		},

		statuscolumn = {
			enabled = true,
			folds = { open = true, git_hl = true },
		},

		zen = {
			toggles = { git_signs = false, indent = false },
		},
	},

	keys = {
		{
			"<leader>un",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss All Notifications",
		},
		{
			"D",
			function()
				Snacks.bufdelete()
			end,
			desc = "Delete Buffer",
		},
		{
			"<leader>.",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<leader>S",
			function()
				Snacks.scratch.select()
			end,
			desc = "Select Scratch Buffer",
		},
		{
			"<c-/>",
			function()
				Snacks.terminal()
			end,
			desc = "Toggle Terminal",
		},
		{
			"<leader>gb",
			function()
				Snacks.gitbrowse()
			end,
			desc = "Git Browse",
			mode = { "n", "v" },
		},
		{
			"<leader>z",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
		},

		------------
		-- Picker --
		------------
		{
			"<leader><space>",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart find files",
		},
		{
			"<leader>/",
			function()
				Snacks.picker.grep({ hidden = true, layout = "ivy_split" })
			end,
			desc = "Grep",
		},
		{
			"<leader>:",
			function()
				Snacks.picker.command_history()
			end,
			desc = "Command history",
		},
		{
			"<leader>n",
			function()
				Snacks.picker.notifications({
					on_show = function()
						vim.cmd.stopinsert()
					end,
				})
			end,
			desc = "Notification history",
		},
		{
			"<leader>w",
			function()
				Snacks.picker.worktrees()
			end,
			desc = "Switch git worktree",
		},
		{
			'"',
			function()
				Snacks.picker.registers()
			end,
			desc = "Registers",
		},

		-- buffer
		{
			"<leader>b",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffer list",
		},

		-- search
		{
			"<leader>sc",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Config files",
		},
		{
			"<leader>sf",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart find files",
		},
		{
			"<leader>sp",
			function()
				Snacks.picker.projects()
			end,
			desc = "Projects",
		},
		{
			"<leader>sr",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent files",
		},
		{
			"<leader>sw",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Grep visual selection or word under cursor",
			mode = { "n", "x" },
		},
		{
			"<leader>s/",
			function()
				Snacks.picker.search_history()
			end,
			desc = "Search history",
		},
		{
			"<leader>sb",
			function()
				Snacks.picker.lines()
			end,
			desc = "Buffer lines",
		},
		{
			"<leader>sB",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "Grep open buffers",
		},
		{
			"<leader>sC",
			function()
				Snacks.picker.commands()
			end,
			desc = "Commands",
		},
		{
			"<leader>sd",
			function()
				Snacks.picker.diagnostics_buffer({
					layout = {
						preview = "main",
						preset = "ivy",
					},
					on_show = function()
						vim.cmd.stopinsert()
					end,
				})
			end,
			desc = "Current buffer diagnostics",
		},
		{
			"<leader>sD",
			function()
				Snacks.picker.diagnostics({
					layout = {
						preview = "main",
						preset = "ivy",
					},
					on_show = function()
						vim.cmd.stopinsert()
					end,
				})
			end,
			desc = "All diagnostics",
		},
		{
			"<leader>sh",
			function()
				Snacks.picker.help()
			end,
			desc = "Search help",
		},
		{
			"<leader>si",
			function()
				Snacks.picker.icons()
			end,
			desc = "Search icons",
		},
		{
			"<leader>sm",
			function()
				Snacks.picker.man()
			end,
			desc = "Search man pages",
		},
		{
			"<leader>su",
			function()
				Snacks.picker.undo()
			end,
			desc = "Undo history",
		},

		-- git
		{
			"<leader>gl",
			function()
				Snacks.picker.git_log({
					on_show = function()
						vim.cmd.stopinsert()
					end,
				})
			end,
			desc = "Git log",
		},
		{
			"<leader>gL",
			function()
				Snacks.picker.git_log_line({
					on_show = function()
						vim.cmd.stopinsert()
					end,
				})
			end,
			desc = "Git log line",
		},
		{
			"<leader>gS",
			function()
				Snacks.picker.git_stash({
					on_show = function()
						vim.cmd.stopinsert()
					end,
				})
			end,
			desc = "Git stash",
		},
		{
			"<leader>gf",
			function()
				Snacks.picker.git_log_file({
					on_show = function()
						vim.cmd.stopinsert()
					end,
				})
			end,
			desc = "Git log file",
		},
	},
}
