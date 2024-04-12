return {
  "nvim-neotest/neotest",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-jest",
  },

  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-jest")({
          jestCommand = "npm test --",
          jestConfigFile = "jest.config.json",
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        }),
      },
    })
  end,

  keys = {
    {
      "<leader>tr",
      ":lua require('neotest').run.run()<CR>",
      desc = "Run the nearest test",
      noremap = true,
      silent = true,
    },
    {
      "<leader>ts",
      ":lua require('neotest').run.stop()<CR>",
      desc = "Stop the nearest test",
      noremap = true,
      silent = true,
    },
    {
      "<leader>to",
      ":lua require('neotest').output.open()<CR>",
      desc = "Open test results",
      noremap = true,
      silent = true,
    },
    {
      "<leader>tO",
      ":lua require('neotest').output.open({ enter = true })<CR>",
      desc = "Open test results and move cursor into window",
      noremap = true,
      silent = true,
    },
    {
      "<leader>ti",
      ":lua require('neotest').summary.toggle()<CR>",
      desc = "Open summary of test results",
      noremap = true,
      silent = true,
    },
    {
      "<leader>tf",
      ":lua require('neotest').run.run(vim.fn.expand('%'))<CR>",
      desc = "Run all jest tests in a file",
      noremap = true,
      silent = true,
    },
    {
      "<leader>tp",
      function()
        require("neotest").output_panel.toggle()
      end,
    },
  },
}
