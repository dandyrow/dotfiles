return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets",
		"moyiz/blink-emoji.nvim",
	},
	version = "1.*",
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
			documentation = { auto_show = true, auto_show_delay_ms = 500 },
			ghost_text = { enabled = true },
			list = { selection = { preselect = false, auto_insert = false } },
			menu = {
				draw = {
					columns = {
						{
							"kind_icon",
							"label",
							gap = 1,
							"kind",
						},
					},

					components = {
						kind_icon = {
							-- (optional) use highlights from mini.icons
							highlight = function(ctx)
								local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
								return hl
							end,
						},
						kind = {
							-- (optional) use highlights from mini.icons
							highlight = function(ctx)
								local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
								return hl
							end,
						},
					},

					treesitter = { "lsp", "snippets" },
				},
			},
		},

		signature = { enabled = true },

		cmdline = {
			enabled = true,
			completion = { menu = { auto_show = true } },
			keymap = { ["<Tab>"] = { "show", "accept" } },
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
			},
		},

    fuzzy = { implementation = "lua" },  -- Rust binary won't download due to 403 error
	},

	opts_extend = { "sources.default" },
}
