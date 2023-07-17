vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set({'n', 'v'}, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap - moves up display lines with k or up
-- physical lines with <int>k and the same with j for down.
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Better window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true })

-- Resize windows with arrow keys
vim.keymap.set('n', '<C-Up>', ':resize -2<CR>', { silent = true })
vim.keymap.set('n', '<C-Down>', ':resize +2<CR>', { silent = true })
vim.keymap.set('n', '<C-Left>', ':vertical resize -2<CR>', { silent = true })
vim.keymap.set('n', '<C-Right>', ':vertical resize +2<CR>', { silent = true })

-- Navigate open buffers
vim.keymap.set('n', '<S-l>', ':bnext<CR>', { silent = true })
vim.keymap.set('n', '<S-h>', ':bprevious<CR>', { silent = true })
vim.keymap.set('n', '<C-q>', ':bdelete<CR>', { silent = true })

-- Keep cursor in middle when performing actions
vim.keymap.set('n', 'J', 'mzJ`z', { silent = true })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { silent = true })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { silent = true })
vim.keymap.set('n', 'n', 'nzzzv', { silent = true })
vim.keymap.set('n', 'N', 'Nzzzv', { silent = true })

-- Quick find and replace. Type word to find then \>/ and it's replacement
vim.keymap.set('n', '<leader>s', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {})

-- Make file executable
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', {})

-- Source open buffer
vim.keymap.set('n', '<leader><leader>', function ()
  vim.cmd('so')
end, { silent = true })

-- Move highlighted text around with shift + j and shift + k
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { silent = true })

-- Allows pasting over highlighted text
vim.keymap.set('v', 'p', '"_dP', { silent = true })

-- Change indent with < & >
vim.keymap.set('v', "<", "<gv", { silent = true })
vim.keymap.set('v', ">", ">gv", { silent = true })

