vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better copy & paste
vim.keymap.set("n", "Y", "y$", { desc = "Yank to end of line" })
vim.keymap.set("n", "p", "p`[", { desc = "Keep cursor at start of pasted text" })
vim.keymap.set("x", "p", [["_d"0P`["]], { desc = "Paste over selected text" })

-- Prevent delete commands from yanking
vim.keymap.set("n", "d", '"_d', { desc = "Prevent delete from yanking" })
vim.keymap.set("n", "dd", '"_dd', { desc = "Prevent delete line from yanking" })

-- Centre screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered) " })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Buffer navigation
vim.keymap.set("n", "L", ":bnext<CR>", { desc = "Next buffer", silent = true })
vim.keymap.set("n", "H", ":bprevious<CR>", { desc = "Previous buffer", silent = true })

-- Splitting & Resizing
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically", silent = true })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally", silent = true })
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height", silent = true })
vim.keymap.set("n", "<C-Down>", ":resize -2 <CR>", { desc = "Decrease window height", silent = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2 <CR>", { desc = "Decrease window width", silent = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2 <CR>", { desc = "Decrease window width", silent = true })

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to window on the left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to window to the right" })

-- Move lines up/down
vim.keymap.set("n", "J", ":m .+1<CR>==", { desc = "Move line down", silent = true })
vim.keymap.set("n", "K", ":m .-2<CR>==", { desc = "Move line up", silent = true })
vim.keymap.set("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Better indenting in visual mode
vim.keymap.set("x", "<", "<gv", { desc = "Decrease selection indent" })
vim.keymap.set("x", ">", ">gv", { desc = "Increase selection indent" })

-- Better window navigation with terminal mode
vim.keymap.set("t", "<C-h>", "<C-\\><C-N><C-w>h", { desc = "Move to window on the left" })
vim.keymap.set("t", "<C-j>", "<C-\\><C-N><C-w>j", { desc = "Move to window below" })
vim.keymap.set("t", "<C-k>", "<C-\\><C-N><C-w>k", { desc = "Move to window above" })
vim.keymap.set("t", "<C-l>", "<C-\\><C-N><C-w>l", { desc = "Move to window to the right" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-N>", { desc = "Enter normal mode when in terminal mode" })

-- Clear search highlight
vim.keymap.set("n", "<leader>c", ":nohl<CR>", { desc = "Clear search highlight", silent = true })

-- Print file path and copy it to clipboard
vim.keymap.set("n", "<leader>pa", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("file:", path)
end)

-- Hover LSP Documentation
vim.keymap.set("n", "<leader>k", function()
	vim.lsp.buf.hover()
end, { desc = "Hover LSP documentation" })

-- Remove windows line endings
vim.keymap.set("n", "<leader>cr", [[:%s/\r//g<CR>]], { desc = "Remove Windows line endings in current file" })
