vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Delete without yanking
vim.keymap.set({ "n", "x" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- Centre screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<c-d>", "<c-d>zz", { desc = "Half page down (centered) " })
vim.keymap.set("n", "<c-u>", "<c-u>zz", { desc = "Half page up (centered)" })

-- Splitting & Resizing
vim.keymap.set("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Split window vertically", silent = true })
vim.keymap.set("n", "<leader>-", "<cmd>split<cr>", { desc = "Split window horizontally", silent = true })
vim.keymap.set("n", "<c-up>", "<cmd>resize +2<cr>", { desc = "Increase window height", silent = true })
vim.keymap.set("n", "<c-down>", "<cmd>resize -2<cr>", { desc = "Decrease window height", silent = true })
vim.keymap.set("n", "<c-left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width", silent = true })
vim.keymap.set("n", "<c-right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width", silent = true })

-- Move lines up/down
vim.keymap.set("n", "<a-j>", "<cmd>m .+1<cr>==", { desc = "Move line down", silent = true })
vim.keymap.set("n", "<a-k>", "<cmd>m .-2<cr>==", { desc = "Move line up", silent = true })
vim.keymap.set("x", "<a-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("x", "<a-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up", silent = true })

-- Better indenting in visual mode
vim.keymap.set("x", "<", "<gv", { desc = "Decrease selection indent" })
vim.keymap.set("x", ">", ">gv", { desc = "Increase selection indent" })

-- Terminal mode: exit to normal mode
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter normal mode when in terminal mode" })

-- Clear search highlight
vim.keymap.set("n", "<leader>cs", "<cmd>nohl<cr>", { desc = "Clear search highlight", silent = true })

-- Print file path and copy it to clipboard
vim.keymap.set("n", "<leader>pa", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("file:", path)
end, { desc = "Print file path & copy it to clipboard" })

-- Open diagnostic list
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic quickfix list" })

-- Remove windows line endings
vim.keymap.set("n", "<leader>cr", [[<cmd>%s/\r//g<cr>]], { desc = "Remove Windows line endings in current file" })

-- Find and replace
vim.keymap.set("n", "<leader>r", function()
  local ok, _ = pcall(function()
    local search = vim.fn.input("Search term: ")
    if search == "" then
      return
    end

    local path = vim.fn.input("Search path, leave blank for cwd (**/*): ")
    if path == "" then
      path = "**/*"
    end

    vim.cmd("silent! vimgrep /" .. search .. "/j " .. path)

    local qf = vim.fn.getqflist()
    if #qf == 0 then
      vim.notify("No matches found", vim.log.levels.INFO)
      return
    end

    local replace = vim.fn.input("Replace with: ")
    if replace == "" then
      return
    end

    vim.cmd("cfdo %s/" .. search .. "/" .. replace .. "/gc | update")
  end)

  if not ok then
    vim.notify("Operation cancelled", vim.log.levels.INFO)
  end
end, { desc = "Find & replace" })
