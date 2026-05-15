return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  branch = "main",
  build = ":TSUpdate",
  commit = "7caec274fd19c12b55902a5b795100d21531391f",
  config = function()
    -- Supported languages found here: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/SUPPORTED_LANGUAGES.md
    require("nvim-treesitter").install({
      "markdown",
      "markdown_inline",
      "regex",
      "bash",
      "python",
      "yaml",
      "go",
      "json",
      "javascript",
      "typescript",
      "nix",
    })
  end,
}
