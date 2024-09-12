return {
  "folke/todo-comments.nvim",

  dependencies = { "nvim-lua/plenary.nvim" },

  config = true,

  lazy = false,

  keys = {
    {
      "]t",
      function()
        require("todo-comments").jump_next()
      end,
      desc = "Next Todo Comment",
    },
    {
      "[t",
      function()
        require("todo-comments").jump_prev()
      end,
      desc = "Previous Todo Comment",
    },
  },
}
