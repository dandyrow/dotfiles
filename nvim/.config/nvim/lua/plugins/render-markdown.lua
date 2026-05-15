return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
  version = "*",
  ft = { "markdown", "Avante" },
  opts = {
    file_types = { "markdown", "Avante" },
    completions = { blink = { enabled = true } },
  },
}
