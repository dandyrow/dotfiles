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

    -- Enter names of LSP servers to install here
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

    require("mason-tool-installer").setup({
      ensure_installed = ensure_installed,
      auto_update = true,
    })

    local capabilities = require("blink.cmp").get_lsp_capabilities()
    require("mason-lspconfig").setup({
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          require("lspconfig")[server_name].setup(server)
        end,
      },
    })
  end,
}
