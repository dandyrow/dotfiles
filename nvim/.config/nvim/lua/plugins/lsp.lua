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

    -- makeWrapper at $out/bin/; @vue/language-server lives two levels up at lib/language-tools/packages/language-server/
    local function get_vue_language_server_path()
      local vue_bin = vim.fn.resolve(vim.fn.exepath("vue-language-server"))
      if vue_bin ~= "" then
        local store_root = vim.fn.fnamemodify(vue_bin, ":h:h")
        local nix_path = store_root .. "/lib/language-tools/packages/language-server"
        if vim.fn.isdirectory(nix_path) == 1 then
          return nix_path
        end
      end
      return vim.fn.stdpath("data")
        .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
    end

    -- Single source of truth for all editor tools; also consumed by Nix (nix/home/default.nix).
    -- https://github.com/dandyrow/dotfiles/blob/main/nvim/.config/nvim/lua/config/tools.json
    local tools_path = vim.fn.stdpath("config") .. "/lua/config/tools.json"
    local tools = vim.json.decode(table.concat(vim.fn.readfile(tools_path), "\n"))

    -- Per-server config for LSP servers that need more than defaults.
    -- Names match the lspconfig server name (= the "name" field in tools.json).
    -- https://github.com/neovim/nvim-lspconfig/tree/master/lsp
    local serverConfigs = {
      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
          },
        },
      },
      basedpyright = {
        settings = {
          basedpyright = { disableOrganizeImports = true },
        },
      },
      gh_actions_ls = {
        filetypes = { "yaml.github" },
      },
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
      vtsls = {
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                {
                  name = "@vue/typescript-plugin",
                  location = get_vue_language_server_path(),
                  languages = { "vue" },
                  configNamespace = "typescript",
                },
              },
            },
          },
        },
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
        },
      },
      nixd = (function()
        local hostname = vim.env.HOSTNAME or vim.fn.hostname()
        local user = vim.env.USER or vim.fn.getenv("USER")
        return {
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
      emmet_language_server = {
        filetypes = { "html", "typescriptreact", "javascriptreact", "css", "scss" },
      },
    }

    local system = require("config.system")

    -- On Nix systems Mason is disabled; all tools are provided by Nix packages.
    -- On non-Nix systems, auto-install all tools via Mason.
    if not system.is_nix() then
      local ensure_installed = {}
      local seen = {}
      for _, tool in ipairs(tools) do
        if not tool.nixOnly and not seen[tool.name] then
          seen[tool.name] = true
          table.insert(ensure_installed, tool.name)
        end
      end

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
    for _, tool in ipairs(tools) do
      if tool.category == "lsp" then
        local config = vim.deepcopy(serverConfigs[tool.name] or {})
        config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})
        vim.lsp.config[tool.name] = config
        vim.lsp.enable(tool.name)
      end
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
