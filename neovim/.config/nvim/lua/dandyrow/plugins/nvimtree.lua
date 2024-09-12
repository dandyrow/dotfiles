return {
  "nvim-tree/nvim-tree.lua",

  lazy = false,

  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  init = function()
    -- disable netrw
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,

  opts = {
    disable_netrw = true,
  },

  keys = {
    {
      "<leader>a",
      "<CMD>NvimTreeToggle<CR>",
      desc = "Toggle nvimtree side window",
    },
  },
}
