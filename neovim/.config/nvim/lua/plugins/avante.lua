return {
  "yetone/avante.nvim",
  build = "make",
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "folke/snacks.nvim",
    "zbirenbaum/copilot.lua",
    "MeanderingProgrammer/render-markdown.nvim",
  },
  opts = {
    instructions_file = "copilot-instructions.md",
    provider = "copilot",
    providers = {
      copilot = {
        model = "claude-sonnet-4",
      },
    },
  },
}
