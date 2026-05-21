-- Shared list of tools managed either by Mason (non-Nix) or Nix packages (Nix systems).
-- Referenced by plugins/lsp.lua to feed mason-tool-installer on non-Nix systems.
--
-- On Nix systems (NixOS, nix-darwin, or standalone Nix), Mason is disabled because
-- Mason-downloaded binaries are dynamically linked against paths that don't exist in
-- the non-FHS Nix environment. Instead, all tools listed here must be provided as
-- Nix packages — see nix/home/default.nix for the corresponding package list.
--
-- When adding a tool here, also add it to nix/home/default.nix.

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
