return {
  'neovim/nvim-lspconfig',

  dependencies = {
    {
      'williamboman/mason.nvim',
      build = ':MasonUpdate',
      config = true,
    },
    {
      'williamboman/mason-lspconfig.nvim',
      opts = {
        -- Automatically install LSPs configured below using Mason
        automatic_installation = true,
      },
    },
    {
      'folke/neodev.nvim',
      opts = {},
    },
  },

  config = function ()
    -- Find server configs using :help lspconfig-all or on nvim-lspconfig GitHub
    local lspconfig = require("lspconfig")

    -- Setup language servers
    lspconfig.lua_ls.setup {
      settings = {
        Lua = {
          runtime = {
            -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
            version = 'LuaJIT',
          },
          diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = { 'vim' },
          },
          workspace = {
            -- Make the server aware of Neovim runtime files
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          -- Do not send telemetry data containing a randomized but unique identifier
          telemetry = {
            enable = false,
          },
        },
      },
    }

    lspconfig.ansiblels.setup {}

    -- Global mappings.
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
    vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
    vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic list' })

    -- Use LspAttach autocommand to only map the following keys
    -- after the language server attaches to the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', {}),
      callback = function(ev)
        -- Buffer local mappings
        -- Code actions.
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = '[r]e[n]ame', buffer = ev.buf })
        vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, { desc = '[c]ode [a]ctions', buffer = ev.buf })
        -- Jump to
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = '[g]oto [D]eclaration', buffer = ev.buf })
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = '[g]oto [d]efinition', buffer = ev.buf })
        vim.keymap.set('n', 'gr', require("telescope.builtin").lsp_references, { desc = '[g]oto [r]eferences', buffer = ev.buf })
        vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, { desc = '[g]oto [I]mplementation', buffer = ev.buf })
        -- Documentation
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover documentation', buffer = ev.buf })
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { desc = 'Signature documentation', buffer = ev.buf })
        -- Format 
        vim.keymap.set('n', '<space>f', function()
          vim.lsp.buf.format { async = true }
        end, { desc = 'Format current buffer with LSP', buffer = ev.buf })
      end,
    })
  end,
}
