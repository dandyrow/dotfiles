return {
  "nvim-treesitter/nvim-treesitter",

  build = ":TSUpdate",

  dependencies = {
    "nvim-treesitter/nvim-treesitter-refactor",
    "HiPhish/nvim-ts-rainbow2",
  },

  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "python",
        "dockerfile",
        "yaml",
        "terraform",
        "go",
        "git_rebase",
        "gitcommit",
        "gitignore",
        "properties",
        "markdown",
        "markdown_inline",
      },

      sync_install = false,

      auto_install = true,

      ignore_install = {},

      highlight = {
        enable = true,
      },
      -- Enable coloured bracket pairs
      rainbow = {
        enable = true,
        query = "rainbow-parens",
        strategy = require("ts-rainbow").strategy.global,
      },
      -- Use treesitter for indentation
      indent = {
        enable = true,
      },
      refactor = {
        highlight_definitions = {
          enable = true,
          clear_on_cursor_move = true,
        },
        highlight_current_scope = {
          enable = true,
        },
        smart_rename = {
          enable = true,
          keymaps = {
            smart_rename = "<leader>rn",
          },
        },
      },
    })
  end,
}
