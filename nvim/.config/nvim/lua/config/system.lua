-- System detection utilities.
-- Used to conditionally enable or disable features depending on the environment.

local M = {}

--- Returns true if Neovim itself is managed by Nix.
--- Detection is based on whether the Neovim executable path is inside
--- /nix/store, which is only true when Neovim was installed via Nix.
---
--- This is more precise than checking for the presence of /nix/store alone,
--- which would also match systems that have Nix installed but are not using
--- it to manage Neovim (e.g. Nix installed as a standalone package manager
--- on a non-NixOS system with a separately installed Neovim).
---
--- On Nix-managed Neovim, Mason-downloaded binaries are broken because they
--- reference dynamic linker paths that do not exist in the non-FHS environment.
--- All tools should therefore be provided via Nix packages instead.
---
---@return boolean
function M.is_nix()
  return vim.fn.exepath("nvim"):find("^/nix/store/") ~= nil
end

return M
