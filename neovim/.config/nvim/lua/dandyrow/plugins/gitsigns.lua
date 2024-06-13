return {
  "lewis6991/gitsigns.nvim",

  opts = {
    current_line_blame = true,
    numhl = true,
    attach_to_untracked = true,
  },

  keys = {
    {
      "]h",
      "<CMD>Gitsigns next_hunk<CR>",
      desc = "Next Git Hunk",
    },
    {
      "[h",
      "<CMD>Gitsigns prev_hunk<CR>",
      desc = "Previous Git Hunk",
    },
    {
      "<leader>hs",
      "<CMD>Gitsigns stage_hunk<CR>",
      desc = "Git Hunk Stage",
    },
    {
      "<leader>hr",
      "<CMD>Gitsigns reset_hunk<CR>",
      desc = "Git Hunk Reset",
    },
    {
      "<leader>hs",
      function()
        require("gitsigns").stage_hunk({
          vim.fn.line("."),
          vim.fn.line("v"),
        })
      end,
      mode = "v",
      desc = "Git Hunk Stage",
    },
    {
      "<leader>hr",
      function()
        require("gitsigns").reset_hunk({
          vim.fn.line("."),
          vim.fn.line("v"),
        })
      end,
      mode = "v",
      desc = "Git Hunk Reset",
    },
    {
      "<leader>hu",
      "<CMD>Gitsigns undo_stage_hunk<CR>",
      desc = "Git Hunk Unstage",
    },
    {
      "<leader>hp",
      "<CMD>Gitsigns preview_hunk<CR>",
      desc = "Git Preview Hunk",
    },
    {
      "<leader>hb",
      function()
        require("gitsigns").blame_line({ full = true })
      end,
      desc = "Git Hunk Blame Line",
    },
    {
      "<leader>hi",
      "<CMD>Gitsigns select_hunk<CR>",
      desc = "Git Hunk Select",
    },
    {
      "<leader>hd",
      "<CMD>Gitsigns toggle_deleted<CR>",
      desc = "Git Hunk Toggle Deleted",
    },
    {
      "<leader>hR",
      "<CMD>Gitsigns reset_buffer<CR>",
      desc = "Git Buffer Reset",
    },
  },
}
