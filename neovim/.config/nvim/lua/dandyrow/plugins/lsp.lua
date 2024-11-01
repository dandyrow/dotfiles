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
        { plugins = { "nvim-dap-ui" }, types = true },
      },
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

      lspconfig.ts_ls.setup({
        capabilities = capabilities,
        init_options = {
          preferences = {
            disableSuggestions = true,
          },
        },
      })

      lspconfig.marksman.setup{}

      lspconfig.nixd.setup({
        cmd = { "nixd" },
        settings = {
          nixd = {
            nixpkgs = {
              expr = "import (builtins.getFlake \"/home/dandyrow/.dotfiles/nix/\").inputs.nixpkgs { }",
            },
            formatting = {
              command = { "nixfmt" },
            }
          }
        }
      })
    end,

    keys = {
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
        "<leader>ls",
        vim.lsp.buf.signature_help,
        desc = "Hover signature documentation",
      },
      {
        "<leader>ld",
        vim.lsp.buf.definition,
        desc = "Go to definition",
      },
      {
        "<leader>lt",
        vim.lsp.buf.type_definition,
        desc = "Go to type definition",
      },
      {
        "<leader>lD",
        vim.lsp.buf.declaration,
        desc = "Go to declaration",
      },
      {
        "<leader>li",
        vim.lsp.buf.implementation,
        desc = "Go to implementation",
      },
      {
        "<leader>la",
        vim.lsp.buf.code_action,
        mode = { "n", "v" },
        desc = "Show code actions",
      },
      {
        "<leader>lr",
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
