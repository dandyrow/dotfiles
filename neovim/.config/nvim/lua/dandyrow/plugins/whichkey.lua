return {
  "folke/which-key.nvim",

  version = "*",

  event = "VeryLazy",

  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,

  config = true,
}
