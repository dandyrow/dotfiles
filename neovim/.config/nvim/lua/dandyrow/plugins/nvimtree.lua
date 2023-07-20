return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function ()
    -- Keymap to open nvim-tree as a sidebar
    vim.keymap.set('n', '<leader>d', ':NvimTreeToggle<CR>', { desc = '[d] toggle nvimtree side window', silent = true })

    -- disable netrw
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require('nvim-tree').setup {
      disable_netrw = true,
    }
  end,
}

