return {
  "saghen/blink.cmp",
  dependencies = {
    {
      "saghen/blink.compat",
      version = "2.*",
      lazy = true,
      opts = {},
    },
    {
      "L3MON4D3/LuaSnip",
      version = "2.*",
      build = "make install_jsregexp",
      dependencies = {
        "rafamadriz/friendly-snippets",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
      opts = {},
    },
    {
      "folke/lazydev.nvim",
      ft = "lua",
      opts = {
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },
    "moyiz/blink-emoji.nvim",
    "fang2hou/blink-copilot",
  },
  version = "1.*",
  opts = {
    keymap = {
      preset = "super-tab",
      ["<CR>"] = { "accept", "fallback" },
    },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "mono",
    },

    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 500 },
      ghost_text = { enabled = true },
      list = { selection = { preselect = false, auto_insert = false } },
      menu = {
        draw = {
          columns = {
            {
              "kind_icon",
              "label",
              gap = 1,
              "kind",
            },
          },

          components = {
            kind_icon = {
              -- (optional) use highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
            kind = {
              -- (optional) use highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
          },

          treesitter = { "lsp", "snippets" },
        },
      },
    },

    cmdline = {
      enabled = true,
      completion = { menu = { auto_show = true } },
      keymap = { ["<Tab>"] = { "show", "accept" } },
    },

    sources = {
      default = {
        "lazydev",
        "lsp",
        "path",
        "buffer",
        "emoji",
        "snippets",
        "copilot",
        "avante_commands",
        "avante_mentions",
        "avante_shortcuts",
        "avante_files",
      },

      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
        emoji = {
          module = "blink-emoji",
          name = "Emoji",
          score_offset = 15, -- Tune by preference
          opts = { insert = true }, -- Insert emoji (default) or complete its name
        },
        copilot = {
          name = "Copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        },
        avante_commands = {
          name = "avante_commands",
          module = "blink.compat.source",
          score_offset = 90, -- show at a higher priority than lsp
          opts = {},
        },
        avante_files = {
          name = "avante_files",
          module = "blink.compat.source",
          score_offset = 100, -- show at a higher priority than lsp
          opts = {},
        },
        avante_mentions = {
          name = "avante_mentions",
          module = "blink.compat.source",
          score_offset = 1000, -- show at a higher priority than lsp
          opts = {},
        },
        avante_shortcuts = {
          name = "avante_shortcuts",
          module = "blink.compat.source",
          score_offset = 1000, -- show at a higher priority than lsp
          opts = {},
        },
      },
    },

    snippets = { preset = "luasnip" },
    fuzzy = { implementation = "lua" }, -- Rust binary won't download due to 403 error
    signature = { enabled = true },
  },

  opts_extend = { "sources.default" },
}
