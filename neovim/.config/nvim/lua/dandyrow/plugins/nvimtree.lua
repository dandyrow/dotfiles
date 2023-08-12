return {
  'nvim-tree/nvim-tree.lua',

  lazy = false,

  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },

  init = function ()
    -- Keymap to open nvim-tree as a sidebar
    vim.keymap.set('n', '<leader>d', ':NvimTreeToggle<CR>', { desc = 'Toggle nvimtree side window', silent = true })

    -- disable netrw
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,

  opts = {
    disable_netrw = true,
  },
}

