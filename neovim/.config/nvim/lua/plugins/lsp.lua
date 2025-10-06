return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "saghen/blink.cmp",
  },
  config = function()
    vim.diagnostic.config({
      virtual_lines = { current_line = true },
      severity_sort = true,
      float = { border = "rounded", source = "if_many" },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "󰅚 ",
          [vim.diagnostic.severity.WARN] = "󰀪 ",
          [vim.diagnostic.severity.INFO] = "󰋽 ",
          [vim.diagnostic.severity.HINT] = "󰌶 ",
        },
        linehl = {
          [vim.diagnostic.severity.ERROR] = "DiagnosticError",
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = "DiagnosticError",
          [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
          [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
          [vim.diagnostic.severity.HINT] = "DiagnosticHint",
        },
      },
    })

    -- Enter names of LSP servers to install below
    -- https://github.com/neovim/nvim-lspconfig/tree/master/lsp
    local servers = {
      lua_ls = {},
      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
          },
        },
      },
      bashls = {},
      basedpyright = {
        settings = {
          basedpyright = { disableOrganizeImports = true },
        },
      },
      gh_actions_ls = {
        filetypes = { "yaml.github" },
      },
      jsonls = {},
      gopls = {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      },
    }

    local function merge_unique(...)
      local seen = {}
      local result = {}

      for _, list in ipairs({ ... }) do
        for _, item in ipairs(list) do
          if not seen[item] then
            seen[item] = true
            table.insert(result, item)
          end
        end
      end

      return result
    end

    local ensure_installed = merge_unique(
      vim.tbl_keys(servers or {}),
      require("plugins.conform").ensure_installed or {},
      require("plugins.lint").ensure_installed or {},
      require("plugins.dap").ensure_installed or {}
    )

    -- Auto install all lsps, formatters, linters, and daps
    -- (mason-lspconfig auto enable disabled as lsps are enabled below)
    require("mason-lspconfig").setup({ automatic_enable = false })
    require("mason-tool-installer").setup({
      ensure_installed = ensure_installed,
      auto_update = true,
    })

    -- Add capabilities, merge lsp configs & enable
    local capabilities = require("blink.cmp").get_lsp_capabilities()
    for server_name, server_config in pairs(servers) do
      server_config.capabilities = vim.tbl_deep_extend("force", capabilities, server_config.capabilities or {})
      vim.lsp.config[server_name] = server_config
      vim.lsp.enable(server_name)
    end
  end,
}
