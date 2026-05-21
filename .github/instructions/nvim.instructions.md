---
applyTo: "nvim/**,**/nvim/**,**/.config/nvim/**"
---

# Neovim (nvim/) scoped guidance

This guidance applies only to files within the Neovim configuration folder(s).

## Principles and implementation rules
- **Lua only**: config must be written in Lua; avoid Vimscript unless unavoidable.
- **Prefer built-in Neovim over plugins**:
  - Use `vim.opt` / `vim.o` / `vim.wo` / `vim.bo` for options.
  - Use `vim.keymap.set` for mappings.
  - Use built-in LSP (`vim.lsp`), diagnostics (`vim.diagnostic`), and Treesitter only if already present.
- **lazy.nvim is the plugin manager** — follow existing specs; don't introduce alternatives.
- Make changes **incremental and minimal**. Avoid refactors or module renames unless explicitly requested.
- Keep configuration **modular**: prefer small `require("...")` modules over monolithic files.
- Avoid global side effects: use local variables; do not pollute `_G`.
- Keymaps: `vim.keymap.set({mode}, lhs, rhs, { desc = "...", silent = true, noremap = true })` — always include `desc`.

## Plugins: strict criteria
Only add a plugin if ALL are true:
1. The feature cannot be implemented with built-in Neovim reasonably.
2. The plugin is widely used and actively maintained.
3. The plugin's scope does not overlap existing plugins in this repo.

When adding a plugin: add a comment explaining why built-in Neovim wasn't sufficient; load it lazily (`event`/`keys`/`cmd`/`ft`) where appropriate.

## lazy.nvim conventions
- Keep specs in the repo's existing layout (`nvim/lua/plugins/*.lua` or similar).
- Each spec: plugin repo string + optional lazy-load keys + `config = function() ... end` or `opts = { ... }`.
- Do not introduce other plugin managers.

## Testing / validation (do when practical)
- `nvim --headless "+qa"` — verify startup without errors.
- If plugin specs changed, ensure lazy.nvim sync is consistent with existing repo workflow.

## Boundaries
- Do not modify unrelated dotfiles outside the Neovim config.
- Do not add secrets (API keys, tokens) to Neovim config.
- Do not change global repo workflows (worktrees, commit rules) from within this scope.

## If uncertain
Ask a short clarifying question rather than guessing, especially when:
- adding a new plugin
- changing plugin manager behaviour
- changing core editing UX defaults (keymaps, leader, navigation primitives)
