return {
  "folke/zen-mode.nvim",

  dependencies = { "folke/twilight.nvim" },

  opts = {
    window = {
      options = {
        signcolumn = "no",
        colorcolumn = "",
      },
    },
  },

  keys = {
    {
      "<leader>z",
      "<CMD>ZenMode<CR>",
      desc = "Toggle ZenMode",
    },
  },
}
