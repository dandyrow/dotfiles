return {
  "neovim/nvim-lspconfig",
  dependencies = {
    {
      "mason-org/mason.nvim",
      opts = {},
      -- Mason binaries are broken on Nix due to non-FHS dynamic linker paths.
      -- Disable on Nix systems; tools should be provided via Nix packages instead.
      enabled = not require("config.system").is_nix(),
    },
    {
      "mason-org/mason-lspconfig.nvim",
      enabled = not require("config.system").is_nix(),
    },
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      enabled = not require("config.system").is_nix(),
    },
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
        -- Note: gh_actions_ls (github-actions-language-server) is not yet in nixpkgs.
        -- On Nix systems this server will be unavailable unless installed manually.
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
      ansiblels = {},
      ts_ls = {},
      nixd = (function()
        local hostname = vim.env.HOSTNAME or vim.fn.hostname()
        local user = vim.env.USER or vim.fn.getenv("USER")
        return {
          mason = false,
          settings = {
            nixd = {
              nixpkgs = {
                expr = 'import (builtins.getFlake "/etc/nixos").inputs.nixpkgs { }',
              },
              options = {
                nixos = {
                  expr = '(builtins.getFlake "/etc/nixos").nixosConfigurations.' .. hostname .. ".options",
                },
                home_manager = {
                  expr = '(builtins.getFlake "/etc/nixos").homeConfigurations."' .. user .. '".options',
                },
              },
            },
          },
        }
      end)(),
      tailwindcss = {
        filetypes = { "html", "css", "typescriptreact", "javascriptreact" },
      },
      cssls = {},
      eslint = {},
      emmet_language_server = {
        filetypes = { "html", "typescriptreact", "javascriptreact", "css", "scss" },
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

    -- Filter out servers which shouldn't be downloaded by mason
    local mason_servers = {}
    for name, config in pairs(servers) do
      if config.mason ~= false then
        table.insert(mason_servers, name)
      end
    end

    local tools = require("config.tools")
    local system = require("config.system")

    -- On Nix systems Mason is disabled; all tools are provided by Nix packages.
    -- On non-Nix systems, auto-install LSPs, formatters, linters, and DAPs via Mason.
    if not system.is_nix() then
      local ensure_installed = merge_unique(mason_servers, tools.formatters, tools.linters, tools.dap_adapters)

      -- Auto install all lsps, formatters, linters, and daps
      -- (mason-lspconfig auto enable disabled as lsps are enabled below)
      require("mason-lspconfig").setup({ automatic_enable = false })
      require("mason-tool-installer").setup({
        ensure_installed = ensure_installed,
        auto_update = false,
        run_on_start = true,
        debounce_hours = 24,
      })
    end

    -- Add capabilities, merge lsp configs & enable
    local capabilities = require("blink.cmp").get_lsp_capabilities()
    for server_name, server_config in pairs(servers) do
      server_config.capabilities = vim.tbl_deep_extend("force", capabilities, server_config.capabilities or {})
      vim.lsp.config[server_name] = server_config
      vim.lsp.enable(server_name)
    end

    -- Document highlight: highlight all references to the symbol under cursor
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local method = vim.lsp.protocol.Methods.textDocument_documentHighlight
        local supports = function()
          return client:supports_method(method, event.buf)
        end

        if client and supports() then
          local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })

          -- Highlight references when cursor rests, clear when it moves
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          -- Clear highlighting when LSP detaches from buffer
          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("lsp-detach", { clear = false }),
            buffer = event.buf,
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
            end,
          })
        end

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
        end
      end,
    })
  end,
}
