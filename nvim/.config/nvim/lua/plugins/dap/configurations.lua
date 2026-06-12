-- More dap configurations can be found at:
-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
local dap = require("dap")
local system = require("config.system")

dap.configurations.rust = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      -- Build the project; vim.system() with wait() avoids blocking the event loop
      vim.notify("cargo build running…", vim.log.levels.INFO)
      local build = vim.system({ "cargo", "build" }, { text = true }):wait()
      if build.code ~= 0 then
        vim.notify("cargo build failed:\n" .. (build.stderr or ""), vim.log.levels.ERROR)
        error("cargo build failed")
      end
      vim.notify("cargo build succeeded", vim.log.levels.INFO)

      -- Get binary path via cargo metadata
      local meta = vim.system({ "cargo", "metadata", "--format-version", "1", "--no-deps" }, { text = true }):wait()
      if meta.code ~= 0 then
        error("Failed to run 'cargo metadata': " .. (meta.stderr or ""))
      end

      local ok, metadata = pcall(vim.fn.json_decode, meta.stdout)
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
    -- On Nix, bashdb is expected on $PATH; on non-Nix it lives under the Mason package.
    pathBashdb = system.is_nix()
      and (vim.fn.exepath("bashdb") ~= "" and vim.fn.exepath("bashdb") or "bashdb")
      or vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
    pathBashdbLib = system.is_nix()
      and (vim.fn.exepath("bashdb") ~= "" and vim.fn.fnamemodify(vim.fn.exepath("bashdb"), ":h") or "")
      or vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir",
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

dap.configurations.python = {
  {
    -- The first three options are required by nvim-dap
    type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
    request = "launch",
    name = "Launch file",

    -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

    program = "${file}", -- This configuration will launch the current file if used.
    pythonPath = function()
      -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
      -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
      -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
      local cwd = vim.fn.getcwd()
      if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
        return cwd .. "/venv/bin/python"
      elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
        return cwd .. "/.venv/bin/python"
      else
        return vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python3"
      end
    end,
  },
}

local js_configs = {
  {
    type = "pwa-node",
    request = "launch",
    name = "Node: Launch current file",
    program = "${file}",
    cwd = "${workspaceFolder}",
    sourceMaps = true,
  },
  {
    type = "pwa-chrome",
    request = "launch",
    name = "Chrome: Launch and attach to dev server",
    url = function()
      local url = vim.fn.input("Dev server URL (default: http://localhost:3000): ")
      return url ~= "" and url or "http://localhost:3000"
    end,
    webRoot = "${workspaceFolder}",
    sourceMaps = true,
  },
}

for _, ft in ipairs({ "javascript", "typescript", "typescriptreact", "javascriptreact" }) do
  dap.configurations[ft] = js_configs
end
