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
    },
    default_format_opts = { lsp_format = "fallback" },
    format_on_save = { timeout_ms = 500 },
  },
  ensure_installed = {
    "stylua",
    -- rustfmt should be installed by rustup
    "beautysh",
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
