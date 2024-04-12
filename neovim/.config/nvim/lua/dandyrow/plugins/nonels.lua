return {
	"nvimtools/none-ls.nvim",

  dependencies = {
    'nvimtools/none-ls-extras.nvim',
  },

	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
        -- Completion
        null_ls.builtins.completion.luasnip,
        null_ls.builtins.completion.spell,

        -- Diagnostics
        null_ls.builtins.diagnostics.actionlint,
        null_ls.builtins.diagnostics.ansiblelint,
        null_ls.builtins.diagnostics.codespell,
        null_ls.builtins.diagnostics.proselint,
        null_ls.builtins.diagnostics.terraform_validate,
        null_ls.builtins.diagnostics.tfsec,
        null_ls.builtins.diagnostics.trail_space,
        null_ls.builtins.diagnostics.yamllint,
        null_ls.builtins.diagnostics.zsh,

        -- Code Actions
        null_ls.builtins.code_actions.gitsigns,
        null_ls.builtins.code_actions.proselint,
        null_ls.builtins.code_actions.refactoring,

        -- Formatting
        null_ls.builtins.formatting.cbfmt,
        null_ls.builtins.formatting.codespell,
        null_ls.builtins.formatting.packer,
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.terraform_fmt,
        null_ls.builtins.formatting.yamlfmt,
        require('none-ls.formatting.eslint'),

        -- Hover
        null_ls.builtins.hover.dictionary,
        null_ls.builtins.hover.printenv,
			},
		})

		vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, {
			desc = "Format Buffer",
			silent = true,
		})
	end,
}
