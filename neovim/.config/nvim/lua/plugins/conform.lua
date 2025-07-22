return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      rust = { "rustfmt" },
    },
    default_format_opts = { lsp_format = "fallback" },
    format_on_save = { timeout_ms = 500 },
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
  ensure_installed = {
    "stylua",
    "rustfmt",
  },
}
