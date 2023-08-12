return {
  'nvim-telescope/telescope.nvim',

  tag = '0.1.2',

  dependencies = {
    'nvim-lua/plenary.nvim'
  },

  init = function ()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Search git files', silent = true })
    vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = 'Search open buffers', silent = true })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Search files', silent = true })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Search by grep', silent = true })
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Search help', silent = true })
  end,

  opts = {},
}

