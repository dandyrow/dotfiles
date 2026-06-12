-- More dap adapters can be found at:
-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
local dap = require("dap")
local system = require("config.system")

dap.adapters.codelldb = {
  type = "executable",
  command = "codelldb",
}

-- On Nix systems Mason is disabled; expect bash-debug-adapter on $PATH
-- (e.g. installed via a Nix devShell or home-manager package).
-- On non-Nix systems Mason provides the adapter under its data directory.
if system.is_nix() then
  dap.adapters.bashdb = {
    type = "executable",
    command = vim.fn.exepath("bash-debug-adapter"),
    name = "bashdb",
  }
else
  dap.adapters.bashdb = {
    type = "executable",
    command = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter",
    name = "bashdb",
  }
end

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
      command = vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python3",
      args = { "-m", "debugpy.adapter" },
      options = {
        source_filetype = "python",
      },
    })
  end
end

-- vscode-js-debug adapter for JavaScript / TypeScript / React debugging.
-- On Nix: provided by pkgs.vscode-js-debug (js-debug-dap binary on PATH).
-- On non-Nix: Mason installs js-debug-adapter; binary at the Mason data path.
local js_debug_cmd
if system.is_nix() then
  js_debug_cmd = vim.fn.exepath("js-debug-dap")
else
  js_debug_cmd = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug-dap"
end

for _, adapter_type in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }) do
  dap.adapters[adapter_type] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = js_debug_cmd,
      args = { "${port}" },
    },
  }
end
