---@diagnostic disable: deprecated
return {
  "nvim-lualine/lualine.nvim",

  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    require("lualine").setup({
      options = {
        theme = "catppuccin",
        icons_enabled = true,
      },
      extensions = { "nvim-tree" },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename", "filesize" },
        lualine_x = {
          {
            require("noice").api.statusline.mode.get,
            cond = require("noice").api.statusline.mode.has,
          },
          "encoding",
          "fileformat",
          "filetype",
        },
        lualine_y = { "searchcount", "selectioncount", "progress", "location" },
        lualine_z = { "tabs" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    })
  end,
}
