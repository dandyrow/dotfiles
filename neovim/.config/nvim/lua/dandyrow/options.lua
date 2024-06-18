-- Write file on :quit, :exit, etc.
vim.opt.autowriteall = true

-- Indent wrapped lines
vim.opt.breakindent = true
vim.opt.breakindentopt = "shift:2"

-- yank to "+" register instead of "*"
vim.opt.clipboard = "unnamedplus"
-- Yank to system clipboard in WSL
vim.g.clipboard = {
  name = "WslClipboard",
  copy = {
    ["+"] = "clip.exe",
    ["*"] = "clip.exe",
  },
  paste = {
    ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enable = 0,
}

vim.opt.colorcolumn = "80"

-- Show completions in a menu even when only one
vim.opt.completeopt = { "menuone", "preview" }

-- Highlight line cursor is on
vim.opt.cursorline = true

-- Tabbing options
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

vim.opt.fileencoding = "utf-8"

-- Search options
vim.opt.ignorecase = true
-- Override ignorecase if search contains capitals
vim.opt.smartcase = true

-- Enable mouse in n,v,i & c modes
vim.opt.mouse = "a"
vim.opt.mousemoveevent = true

-- Line number options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 2

-- Max num items to show in popup menu
vim.opt.pumheight = 20

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
-- Character to show on wrapped lines
vim.opt.showbreak = "> "

-- Disables mode message on last line
vim.opt.showmode = false

vim.opt.signcolumn = "yes"

vim.opt.spell = true
vim.opt.spelllang = { "en_gb" }

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.swapfile = false

vim.opt.termguicolors = true

vim.opt.undofile = true

vim.opt.updatetime = 50
