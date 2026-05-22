return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
  version = "*",
  ft = { "markdown" },
  opts = {
    file_types = { "markdown" },
    completions = { blink = { enabled = true } },
  },
}
