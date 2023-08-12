return {
	"mhartington/formatter.nvim",

	config = function()
		require("formatter").setup({

			logging = false,
			filetype = {
				lua = {
					require("formatter.filetypes.lua").stylua,
				},

				yaml = {
					require("formatter.filetypes.yaml").yamlfmt,
				},

				terraform = {
					require("formatter.filetypes.terraform").terraformfmt,
				},

				hcl = {
					require("formatter.filetypes.terraform").terraformfmt,
				},

				-- Formatter config for any filetype
				["*"] = {
					require("formatter.filetypes.any").remove_trailing_whitespace,
				},
			},
		})

		vim.keymap.set("n", "<leader>f", "<CMD>Format<CR>", {
      desc = "[f] format buffer",
      silent = true
    })
		vim.keymap.set("n",	"<leader>F", "<CMD>FormatWrite<CR>", {
      desc = "[F] format and write buffer",
      silent = true
    })
	end,
}
