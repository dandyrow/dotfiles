return {
  "romgrk/barbar.nvim",

  version = "^1.0.0",

  dependencies = {
    "lewis6991/gitsigns.nvim",
    "nvim-tree/nvim-web-devicons",
  },

  lazy = false,

  init = function()
    vim.g.barbar_auto_setup = false
  end,

  opts = {
    insert_at_end = true,
    tabpages = false,
    sidebar_filetypes = {
      NvimTree = true,
    },
    icons = {
      diagnostics = {
        [vim.diagnostic.severity.ERROR] = { enabled = true },
        [vim.diagnostic.severity.WARN] = { enabled = false },
        [vim.diagnostic.severity.INFO] = { enabled = false },
        [vim.diagnostic.severity.HINT] = { enabled = true },
      },
      gitsigns = {
        added = {
          enabled = true,
          icon = "+",
        },
        changed = {
          enabled = true,
          icon = "~",
        },
        deleted = {
          enabled = true,
          icon = "-",
        },
      },
    },
  },

  keys = {
    {
      "<S-l>",
      "<CMD>bnext<CR>",
      desc = "Move to next buffer",
    },
    {
      "<S-h>",
      "<CMD>bprevious<CR>",
      desc = "Move to previous buffer",
    },
    {
      "<C-q>",
      "<CMD>BufferClose<CR>",
      desc = "Close current buffer",
    },
  },
}
