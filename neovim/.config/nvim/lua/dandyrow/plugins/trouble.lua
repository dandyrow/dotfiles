return {
  "folke/trouble.nvim",

  dependencies = { "nvim-tree/nvim-web-devicons" },

  init = function ()
    vim.keymap.set('n', '<leader>p', '<cmd>TroubleToggle<CR>', {
      silent = true,
      noremap = true,
      desc = 'Toggle Trouble'
    })
  end,

  opts = {},
}
