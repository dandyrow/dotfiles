return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- Link to docs: https://github.com/mfussenegger/nvim-lint
    local lint = require("lint")
    lint.linters_by_ft = {
      -- lua = { "luacheck" }, requires luarocks
      sh = { "shellcheck" },
      python = { "ruff" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>l", function()
      lint.try_lint()
    end, { desc = "Lint current file" })
  end,
  ensure_installed = {
    -- "luacheck",
    "shellcheck",
    "ruff",
  },
}
