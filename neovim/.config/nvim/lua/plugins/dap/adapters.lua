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

dap.adapters.python = function(cb, config)
  if config.request == "attach" then
    ---@diagnostic disable-next-line: undefined-field
    local port = (config.connect or config).port
    ---@diagnostic disable-next-line: undefined-field
    local host = (config.connect or config).host or "127.0.0.1"
    cb({
      type = "server",
      port = assert(port, "`connect.port` is required for a python `attach` configuration"),
      host = host,
      options = {
        source_filetype = "python",
      },
    })
  else
    cb({
      type = "executable",
      command = "/usr/sbin/python",
      args = { "-m", "debugpy.adapter" },
      options = {
        source_filetype = "python",
      },
    })
  end
end
