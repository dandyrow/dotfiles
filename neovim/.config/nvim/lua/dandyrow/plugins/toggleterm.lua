return {
  'akinsho/toggleterm.nvim',

  opts = {
    open_mapping = [[<C-\>]],
    direction = 'float',
    float_opts = {
      border = 'curved',
    },
  },

  init = function()
    function _G.set_terminal_keymaps()
      local opts = {buffer = 0}
      vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
      vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
      vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
      vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
    end

    -- if you only want these mappings for toggle term use term://*toggleterm#* instead
    vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

    local Terminal = require('toggleterm.terminal').Terminal

    local htop = Terminal:new({ cmd = 'htop', hidden = true })
    function _HTOP_TOGGLE()
      htop:toggle()
    end
    vim.keymap.set('n', '<leader>th', '<CMD>lua _HTOP_TOGGLE()<CR>', { desc = 'Toggle htop float', noremap = true, silent = true })

    local lazygit = Terminal:new({ cmd = 'lazygit', hidden = true })
    function _LGIT_TOGGLE()
      lazygit:toggle()
    end
    vim.keymap.set('n', '<leader>tg', '<CMD>lua _LGIT_TOGGLE()<CR>', { desc = 'Toggle lazygit float', noremap = true, silent = true })
  end,
}
