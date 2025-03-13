return {
  "catppuccin/nvim",

  name = "catppuccin",

  priority = 1000,

  init = function()
    -- Safely activate colourscheme
    local status_ok, _ = pcall(vim.cmd.colorscheme, "catppuccin")
    if not status_ok then
      vim.notify("colorscheme catppuccin not found!")
      return
    end
  end,

  opts = {
    show_end_of_buffer = true,
    term_colors = true,
    dim_inactive = {
      enabled = true,
      shade = "dark",
      percentage = 0.15,
    },
    integrations = {
      barbecue = {
        dim_dirname = true,
        bold_basename = true,
        dim_context = false,
        alt_background = false,
      },
      blink_cmp = true,
      gitsigns = true,
      lsp_trouble = true,
      markdown = true,
      native_lsp = {
        enabled = true,
        virtual_text = {
          errors = { "italic" },
          hints = { "italic" },
          warnings = { "italic" },
          information = { "italic" },
        },
        underlines = {
          errors = { "underline" },
          hints = { "underline" },
          warnings = { "underline" },
          information = { "underline" },
        },
        inlay_hints = {
          background = true,
        },
      },
      nvimtree = true,
      snacks = {
        enabled = true,
        indent_scope_color = "lavender",
      },
      treesitter = true,
      ts_rainbow2 = true,
      which_key = true,
    },
  },

  config = function ()
    require("catppuccin").setup {
      custom_highlights = function (colors)
        return {
          BlinkCmpGhostText = { fg = colors.overlay0, style = { "italic" } },
        }
      end,
    }
  end,
}
