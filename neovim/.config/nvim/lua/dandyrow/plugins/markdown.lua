return {
  {
    "MeanderingProgrammer/render-markdown.nvim",

    version = "*",

    opts = {},

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
  {
    "iamcco/markdown-preview.nvim",

    cmd = {
      "MarkdownPreviewToggle",
      "MarkdownPreview",
      "MarkdownPreviewStop",
    },

    ft = { "markdown" },

    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
}
