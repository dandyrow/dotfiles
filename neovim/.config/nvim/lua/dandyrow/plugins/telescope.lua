return {
  {
    "nvim-telescope/telescope.nvim",

    dependencies = {
      "nvim-lua/plenary.nvim",

      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },

    opts = {
      defaults = {
        mappings = {
          i = {
            ["<C-u>"] = false,
            ["<C-d>"] = false,
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
          },
        },
      },
    },

    keys = {
      {
        "<leader>sf",
        "<CMD>Telescope find_files hidden=true<CR>",
        desc = "Search Files",
      },
      {
        "<leader>so",
        "<CMD>Telescope oldfiles<CR>",
        desc = "Search recent files",
      },
      {
        "<leader>sh",
        "<CMD>Telescope help_tags<CR>",
        desc = "Search Help",
      },
      {
        "<leader>sw",
        "<CMD>Telescope grep_string<CR>",
        desc = "Search current Word",
      },
      {
        "<leader>sg",
        "<CMD>Telescope live_grep<CR>",
        desc = "Search by Grep",
      },
      {
        "<leader>sd",
        "<CMD>Telescope diagnostics<CR>",
        desc = "Searc Diagnostics",
      },
      {
        "<leader>sb",
        "<CMD>Telescope buffers<CR>",
        desc = "Search open Buffers",
      },
      {
        "<leader>st",
        "<CMD>TodoTelescope<CR>",
        desc = "Search Todo, bug, etc. comments",
      },
      {
        "<leader>gf",
        "<CMD>Telescope git_files<CR>",
        desc = "Git Files",
      },
      {
        "<leader>/",
        "<CMD>Telescope current_buffer_fuzzy_find<CR>",
        desc = "Fuzzily search in current buffer",
      },
      {
        "<leader>sr",
        function()
          require("telescope.builtin").lsp_references()
        end,
        desc = "Show references",
      },
    },
  },
  {
    -- Used for code actions
    "nvim-telescope/telescope-ui-select.nvim",

    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })

      require("telescope").load_extension("ui-select")
    end,
  },
}
