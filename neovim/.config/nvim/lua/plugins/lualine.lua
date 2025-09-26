return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "echasnovski/mini.icons" },
  config = function()
    require("lualine").setup({
      options = {
        theme = "catppuccin",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename", "filesize" },
        lualine_x = {
          {
            ---@diagnostic disable: deprecated, undefined-field
            require("noice").api.statusline.mode.get,
            cond = require("noice").api.statusline.mode.has,
            ---@diagnostic enable: deprecated, undefined-field
          },
          "encoding",
          "fileformat",
          "filetype",
        },
        lualine_y = { "searchcount", "selectioncount", "location" },
        lualine_z = { "tabs" },
      },
    })
  end,
}
