return {
  "nvim-treesitter/nvim-treesitter",

  build = ":TSUpdate",

  dependencies = {
    "nvim-treesitter/nvim-treesitter-refactor",
    "HiPhish/rainbow-delimiters.nvim",
  },

  config = function()
    require("nvim-treesitter.configs").setup({
      sync_install = false,
      auto_install = true,
      ignore_install = {},
      highlight = {
        enable = true,
      },
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
