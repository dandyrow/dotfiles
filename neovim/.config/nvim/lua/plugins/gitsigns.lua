return {
  "lewis6991/gitsigns.nvim",

  opts = {
    current_line_blame = true,
    attach_to_untracked = true,
  },

  keys = {
    {
      "]h",
      "<CMD>Gitsigns next_hunk<CR>",
      desc = "Git hunk next",
    },
    {
      "[h",
      "<CMD>Gitsigns prev_hunk<CR>",
      desc = "Git hunk previous",
    },
    {
      "<leader>hs",
      "<CMD>Gitsigns stage_hunk<CR>",
      desc = "Git hunk stage",
    },
    {
      "<leader>hr",
      "<CMD>Gitsigns reset_hunk<CR>",
      desc = "Git hunk reset",
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
      desc = "Git hunk stage",
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
      desc = "Git hunk reset",
    },
    {
      "<leader>hS",
      "<CMD>Gitsigns stage_buffer<CR>",
      desc = "Git buffer stage"
    },
    {
      "<leader>hR",
      "<CMD>Gitsigns reset_buffer<CR>",
      desc = "Git buffer reset",
    },
    {
      "<leader>hp",
      "<CMD>Gitsigns preview_hunk<CR>",
      desc = "Git hunk preview",
    },
    {
      "<leader>hi",
      "<CMD>Gitsigns preview_hunk_inline<CR>",
      desc = "Git hunk preview (inline)"
    },
    {
      "<leader>hb",
      function()
        require("gitsigns").blame_line({ full = true })
      end,
      desc = "Git hunk blame line",
    },
    {
      "<leader>hu",
      "<CMD>Gitsigns undo_stage_hunk<CR>",
      desc = "Git hunk unstage",
    },
    {
      "<leader>hv",
      "<CMD>Gitsigns select_hunk<CR>",
      desc = "Git hunk select",
    },
    {
      "<leader>hd",
      "<CMD>Gitsigns toggle_deleted<CR>",
      desc = "Git hunk toggle deleted",
    },
  },
}
