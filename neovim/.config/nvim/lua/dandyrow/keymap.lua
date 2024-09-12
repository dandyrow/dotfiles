vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap - moves up display lines with k or up
-- physical lines with <int>k and the same with j for down.
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to window on the left", silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to window below", silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to window above", silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to window to the right", silent = true })

-- Better window navigation with terminal mode
vim.keymap.set("t", "<C-h>", "<C-\\><C-N><C-w>h", { desc = "Move to window on the left", silent = true })
vim.keymap.set("t", "<C-j>", "<C-\\><C-N><C-w>j", { desc = "Move to window below", silent = true })
vim.keymap.set("t", "<C-k>", "<C-\\><C-N><C-w>k", { desc = "Move to window above", silent = true })
vim.keymap.set("t", "<C-l>", "<C-\\><C-N><C-w>l", { desc = "Move to window to the right", silent = true })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-N>", { desc = "Enter normal mode when in terminal mode" })

-- Resize windows with arrow keys
vim.keymap.set("n", "<C-Up>", ":resize -2<CR>", { desc = "Increase size of top window", silent = true })
vim.keymap.set("n", "<C-Down>", ":resize +2<CR>", { desc = "Decrease size of top window", silent = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Increase size of right window", silent = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Decrease size of right window", silent = true })

-- Keep cursor in middle when performing action
vim.keymap.set("n", "J", "mzJ`z", { desc = "Concatenate line below", silent = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Page down", silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Page up", silent = true })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result", silent = true })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result", silent = true })

-- Quick find and replace. Type word to find then \>/ and it's replacement
vim.keymap.set(
  "n",
  "<leader>rc",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gc<Left><Left><Left>]],
  { desc = "Find & replace confirm" }
)
vim.keymap.set(
  "n",
  "<leader>ra",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Find & replace all" }
)

-- Move highlighted text around with shift + j and shift + k
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Shift visual selection down", silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Shift visual selection up", silent = true })

-- Allows pasting over highlighted text
vim.keymap.set("v", "p", '"_dP', { silent = true })

-- Change indent with < & >
vim.keymap.set("v", "<", "<gv", { desc = "Decrease indent of visual selection", silent = true })
vim.keymap.set("v", ">", ">gv", { desc = "Increase indent of visual selection", silent = true })

vim.keymap.set("n", "<C-c>", "<CMD>nohl<CR>", { desc = "Clear search highlight" })
