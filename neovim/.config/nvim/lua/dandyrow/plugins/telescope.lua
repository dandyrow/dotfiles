return {
  'nvim-telescope/telescope.nvim',

  tag = '0.1.2',

  dependencies = {
    'nvim-lua/plenary.nvim'
  },

  init = function ()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'search [g]it [f]iles', silent = true })
    vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[s]earch open [b]uffers', silent = true })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[s]earch [f]iles', silent = true })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[s]earch by [g]rep', silent = true })
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[s]earch [h]elp', silent = true })
  end,

  opts = {},
}

