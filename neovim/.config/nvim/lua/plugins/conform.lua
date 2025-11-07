return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    -- Link to docs: https://github.com/stevearc/conform.nvim
    formatters_by_ft = {
      lua = { "stylua" },
      rust = { "rustfmt" },
      sh = { "beautysh" },
      python = { "ruff_organize_imports", "ruff_fix", "ruff_format" },
      ["yaml.ansible"] = { "ansible-lint" },
      yaml = { "yamlfmt" },
      go = { "gofumpt" },
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
    },
    default_format_opts = { lsp_format = "fallback" },
    format_on_save = { timeout_ms = 500 },
  },
  ensure_installed = {
    "stylua",
    -- rustfmt should be installed by rustup
    "beautysh",
    "ruff",
    "ansible-lint",
    "yamlfmt",
    "gofumpt",
    "eslint_d",
  },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true })
      end,
      desc = "Format current file",
    },
  },
}
