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
      "markdown-inline",
      "regex",
      "bash",
      "python",
      "yaml",
      "go",
      "json",
      "javascript",
      "typescript",
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown" },
      callback = function()
        vim.treesitter.start()
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
