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
    "disrupted/blink-cmp-conventional-commits",
    "brenoprata10/nvim-highlight-colors",
  },
  version = "1.*",
  opts = {
    keymap = {
      preset = "super-tab",
      ["<CR>"] = { "accept", "fallback" },
    },

    appearance = {
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
              text = function(ctx)
                local icon = ctx.kind_icon
                if ctx.item.source_name == "LSP" then
                  local color_item = require("nvim-highlight-colors").format(ctx.item.documentation, { kind = ctx.kind })
                  if color_item and color_item.abbr ~= "" then
                    icon = color_item.abbr
                  end
                end
                return icon .. ctx.icon_gap
              end,
              highlight = function(ctx)
                if ctx.item.source_name == "LSP" then
                  local color_item = require("nvim-highlight-colors").format(ctx.item.documentation, { kind = ctx.kind })
                  if color_item and color_item.abbr_hl_group then
                    return color_item.abbr_hl_group
                  end
                end
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
        "conventional_commits",
        "snippets",
        "copilot",
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
        conventional_commits = {
          name = "Conventional Commits",
          module = "blink-cmp-conventional-commits",
          enabled = function()
            return vim.bo.filetype == "gitcommit"
          end,
        },
        copilot = {
          name = "Copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        },
      },
    },

    snippets = { preset = "luasnip" },
    fuzzy = { implementation = "prefer_rust_with_warning" },
    signature = { enabled = true },
  },

  opts_extend = { "sources.default" },
}
