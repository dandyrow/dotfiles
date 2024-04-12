return {
  {
    'nvim-telescope/telescope.nvim',

    tag = '0.1.2',

    dependencies = {
      'nvim-lua/plenary.nvim'
    },

    init = function ()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Search git files', silent = true })
      vim.keymap.set('n', '<leader>tb', builtin.buffers, { desc = 'Search open buffers', silent = true })
      vim.keymap.set('n', '<leader>tf', builtin.find_files, { desc = 'Search files', silent = true })
      vim.keymap.set('n', '<leader>tg', builtin.live_grep, { desc = 'Search by grep', silent = true })
      vim.keymap.set('n', '<leader>th', builtin.help_tags, { desc = 'Search help', silent = true })
    end,

    opts = {},
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',

    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {}
          }
        }
      })

      require("telescope").load_extension("ui-select")
    end
  },
}

