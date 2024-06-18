return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true,
    lazy = false,
  },
  {
    "williamboman/mason-lspconfig.nvim",

    lazy = false,

    dependencies = {
      "williamboman/mason.nvim",
    },

    opts = {
      automatic_installation = true,
    },
  },
  {
    -- Configures lua_ls for editing Neovim config
    "folke/lazydev.nvim",

    ft = "lua",

    opts = {
      library = {
        { plugins = { "nvim-dap-ui" }, types = true }
      }
    },
  },
  {
    "neovim/nvim-lspconfig",

    lazy = false,

    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            telemetry = {
              enable = false,
            },
          },
        },
      })

      lspconfig.ansiblels.setup({
        capabilities = capabilities,
      })

      lspconfig.eslint.setup({
        capabilities = capabilities,
      })

      lspconfig.tsserver.setup({
        capabilities = capabilities,
        init_options = {
          preferences = {
            disableSuggestions = true,
          },
        },
      })
    end,

    keys = {
      {
        "]d",
        vim.diagnostic.goto_next,
        desc = "Go to next diagnostic message",
      },
      {
        "[d",
        vim.diagnostic.goto_next,
        desc = "Go to previous diagnostic message",
      },
      {
        "<leader>e",
        vim.diagnostic.open_float,
        desc = "Open floating diagnostic message",
      },
      {
        "<leader>q",
        vim.diagnostic.setloclist,
        desc = "Open diagnostic list",
      },
      {
        "K",
        vim.lsp.buf.hover,
        desc = "Hover symbol documentation",
      },
      {
        "S",
        vim.lsp.buf.signature_help,
        desc = "Hover signature documentation",
      },
      {
        "gd",
        vim.lsp.buf.definition,
        desc = "Go to definition",
      },
      {
        "gt",
        vim.lsp.buf.type_definition,
        desc = "Go to type definition",
      },
      {
        "gD",
        vim.lsp.buf.declaration,
        desc = "Go to declaration",
      },
      {
        "gi",
        vim.lsp.buf.implementation,
        desc = "Go to implementation",
      },
      {
        "gr",
        function()
          require("telescope.builtin").lsp_references()
        end,
        desc = "Show references",
      },
      {
        "<leader>ca",
        vim.lsp.buf.code_action,
        mode = { "n", "v" },
        desc = "Show code actions",
      },
      {
        "<leader>rn",
        vim.lsp.buf.rename,
        mode = { "n", "v" },
        desc = "Rename symbol",
      },
      {
        "<leader>f",
        vim.lsp.buf.format,
        desc = "Format buffer",
      },
    },
  },
}
