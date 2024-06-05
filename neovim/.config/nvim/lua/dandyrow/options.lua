vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.autowriteall = true

vim.opt.backup = false
vim.opt.clipboard = "unnamedplus"
vim.opt.iskeyword:append("-")
vim.opt.completeopt = { "menuone", "preview" }
vim.opt.conceallevel = 0
vim.opt.colorcolumn = "80"
vim.opt.pumheight = 20
vim.opt.showmode = false
vim.opt.wrap = false

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 2

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.fileencoding = "utf-8"
vim.opt.mouse = "a"

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.swapfile = false
vim.opt.undodir = os.getenv("XDG_CACHE_HOME") .. "/nvim/undodir"
vim.opt.undofile = true

vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

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
