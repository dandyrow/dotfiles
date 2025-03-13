return {
  "NeogitOrg/neogit",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-tree/nvim-web-devicons",
  },

  config = true,

  keys = {
    {
      "<leader>gs",
      "<CMD>Neogit<CR>",
      desc = "Git Status",
    },
    {
      "<leader>gc",
      "<CMD>Neogit commit<CR>",
      desc = "Git Commit",
    },
    {
      "<leader>gp",
      "<CMD>Neogit pull<CR>",
      desc = "Git Pull",
    },
    {
      "<leader>gP",
      "<CMD>Neogit push<CR>",
      desc = "Git Push",
    },
    {
      "<leader>gb",
      "<CMD>Neogit branch<CR>",
      desc = "Git Branch",
    },
    {
      "<leader>gr",
      "<CMD>Neogit rebase<CR>",
      desc = "Git Rebase",
    },
    {
      "<leader>gR",
      "<CMD>Neogit reset<CR>",
      desc = "Git Reset",
    },
    {
      "<leader>gd",
      function()
        if require("diffview.lib").get_current_view() then
          -- Current tabpage is a Diffview; close it
          vim.cmd.DiffviewClose()
        else
          -- No open Diffview exists: open a new one
          vim.cmd.DiffviewOpen()
        end
      end,
      desc = "Git Diff",
    },
  },
}
