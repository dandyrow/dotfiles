return {
	"saghen/blink.cmp",

	dependencies = {
		"rafamadriz/friendly-snippets",
		"moyiz/blink-emoji.nvim",
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = {},
		},
	},

	version = "*",

	opts = {
		keymap = {
			preset = "super-tab",
			["<CR>"] = { "accept", "fallback" },
		},

		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},

		completion = {
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 500,
			},

			ghost_text = {
				enabled = true,
			},

			list = {
				selection = {
					preselect = false,
					auto_insert = false,
				},
			},

			menu = {
				draw = {
					columns = {
						{
							"label",
							"kind",
							gap = 1,
							"kind_icon",
						},
					},
				},
			},
		},

		cmdline = {
			enabled = true,
			completion = {
				menu = {
					auto_show = true,
				},
			},
			keymap = {
				["<Tab>"] = { "show", "accept" },
			},
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer", "emoji" },

			providers = {
				emoji = {
					module = "blink-emoji",
					name = "Emoji",
					score_offset = 15, -- Tune by preference
					opts = { insert = true }, -- Insert emoji (default) or complete its name
				},

				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
			},
		},
	},

	opts_extend = { "sources.default" },
}
