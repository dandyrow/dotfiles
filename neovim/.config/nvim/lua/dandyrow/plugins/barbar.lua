return {
  "romgrk/barbar.nvim",

  dependencies = {
    "lewis6991/gitsigns.nvim",
    "nvim-tree/nvim-web-devicons",
  },

  init = function()
    vim.g.barbar_auto_setup = false

    -- Navigate open buffers
    vim.keymap.set("n", "<S-l>", ":bnext<CR>", { desc = "Move to next buffer", silent = true })
    vim.keymap.set("n", "<S-h>", ":bprevious<CR>", { desc = "Move to previous buffer", silent = true })
    vim.keymap.set("n", "<C-q>", ":BufferClose<CR>", { desc = "Close current buffer", silent = true })
  end,

  opts = {
    insert_at_end = true,
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

  version = "^1.0.0",
}
