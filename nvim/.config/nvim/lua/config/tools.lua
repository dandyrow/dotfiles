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
  -- goimports is not available as a standalone package in nixpkgs (gotools conflicts
  -- with gopls). On Nix, goimports functionality is covered by gopls instead.
  -- Mason installs it on non-Nix systems.
  "goimports",
  "gofumpt",
  "eslint_d",
  "prettier",
}

M.linters = {
  "shellcheck",
  "ruff",
  "actionlint",
  "ansible-lint",
  -- jsonlint is not in nixpkgs; on Nix systems JSON linting is handled by
  -- jsonls (vscode-langservers-extracted) instead. Mason installs it on non-Nix.
  "jsonlint",
  "golangci-lint",
}

M.dap_adapters = {
  "codelldb",
  -- bash-debug-adapter is not in nixpkgs; Mason installs it on non-Nix systems.
  "bash-debug-adapter",
  "debugpy",
  "delve",
  "js-debug-adapter",
}

return M
