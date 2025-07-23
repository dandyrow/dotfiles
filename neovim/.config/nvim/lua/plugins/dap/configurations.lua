-- More dap configurations can be found at:
-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
local dap = require("dap")

dap.configurations.rust = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      -- Run cargo build before launching
      local build = vim.fn.system("cargo build")
      print(build)

      -- Get binary path
      local handle = io.popen("cargo metadata --format-version 1 --no-deps")
      if not handle then
        error("Failed to run 'cargo metadata'")
      end
      local result = handle:read("*a")
      handle:close()

      local ok, metadata = pcall(vim.fn.json_decode, result)
      if not ok or not metadata then
        error("Failed to parse cargo metadata")
      end

      local target_dir = metadata["target_directory"]
      local package_name = metadata.packages[1].name
      return target_dir .. "/debug/" .. package_name
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

dap.configurations.sh = {
  {
    type = "bashdb",
    request = "launch",
    name = "Launch file",
    showDebugOutput = true,
    pathBashdb = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
    pathBashdbLib = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir",
    trace = true,
    file = "${file}",
    program = "${file}",
    cwd = "${workspaceFolder}",
    pathCat = "cat",
    pathBash = "/bin/bash",
    pathMkfifo = "mkfifo",
    pathPkill = "pkill",
    args = {},
    argsString = "",
    env = {},
    terminalKind = "integrated",
  },
}
