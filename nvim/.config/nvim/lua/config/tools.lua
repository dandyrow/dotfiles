-- Shared list of tools to install via Mason.
-- Referenced by plugins/lsp.lua to feed mason-tool-installer.
-- Add formatters, linters, and DAP adapters here alongside LSP servers.

local M = {}

M.formatters = {
  "stylua",
  "beautysh",
  "ruff",
  "ansible-lint",
  "yamlfmt",
  "goimports",
  "gofumpt",
  "eslint_d",
}

M.linters = {
  "shellcheck",
  "ruff",
  "actionlint",
  "ansible-lint",
  "jsonlint",
  "golangci-lint",
  "eslint_d",
}

M.dap_adapters = {
  "codelldb",
  "bash-debug-adapter",
  "debugpy",
  "delve",
}

return M
