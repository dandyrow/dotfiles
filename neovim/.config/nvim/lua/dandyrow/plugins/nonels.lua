return {
  "nvimtools/none-ls.nvim",

  lazy = false,

  dependencies = {
    "nvimtools/none-ls-extras.nvim",
  },

  config = function()
    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        -- Diagnostics
        null_ls.builtins.diagnostics.actionlint,
        null_ls.builtins.diagnostics.ansiblelint,
        null_ls.builtins.diagnostics.codespell,
        null_ls.builtins.diagnostics.trail_space,
        null_ls.builtins.diagnostics.yamllint,
        null_ls.builtins.diagnostics.zsh,

        -- Formatting
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.yamlfmt,
        require("none-ls.formatting.eslint"),

        -- Hover
        null_ls.builtins.hover.dictionary,
        null_ls.builtins.hover.printenv,
      },
    })
  end,
}
