return {
  "epwalsh/obsidian.nvim",

  version = "*",

  lazy = true,

  event = {
    "BufReadPre " .. vim.fn.expand("~") .. "/vaults/*.md",
    "BufNewFile " .. vim.fn.expand("~") .. "/vaults/*.md",
  },

  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
  },

  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/vaults/personal",
      },
      {
        name = "work",
        path = "~/vaults/work",
      },
    },
    ui = {
      enable = false,
    },
  },
}
