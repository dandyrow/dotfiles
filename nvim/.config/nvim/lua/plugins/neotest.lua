return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "marilari88/neotest-jest",
    "marilari88/neotest-vitest",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-jest"),
        require("neotest-vitest"),
      },
    })
  end,
  keys = {
    {
      "<leader>tr",
      function()
        require("neotest").run.run()
      end,
      desc = "Test: run nearest",
    },
    {
      "<leader>tf",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      desc = "Test: run file",
    },
    {
      "<leader>ts",
      function()
        require("neotest").summary.toggle()
      end,
      desc = "Test: toggle summary",
    },
    {
      "<leader>to",
      function()
        require("neotest").output_panel.toggle()
      end,
      desc = "Test: toggle output panel",
    },
  },
}
