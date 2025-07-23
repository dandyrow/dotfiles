-- More dap adapters can be found at:
-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
local dap = require("dap")

dap.adapters.codelldb = {
  type = "executable",
  command = "codelldb",
}

dap.adapters.bashdb = {
  type = "executable",
  command = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter",
  name = "bashdb",
}
