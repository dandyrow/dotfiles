return {
  "nvimdev/dashboard-nvim",

  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  event = "VimEnter",

  opts = function()
    local logo = [[
 _______________            
< Neovim rocks! >           
 ---------------            
        \   ^__^            
         \  (oo)\_______    
            (__)\       )\/\
                ||----w |   
                ||     ||   
    ]]

    logo = string.rep("\n", 8) .. logo .. "\n\n"

    local opts = {
      theme = "doom",
      config = {
        header = vim.split(logo, "\n"),
        center = {
          {
            action = "Telescope find_files hidden=true",
            desc = "Find Files",
            icon = " ",
            key = "f",
          },
          {
            action = "Telescope oldfiles",
            desc = " Recent Files",
            icon = " ",
            key = "r",
          },
          {
            action = "Telescope live_grep",
            desc = " Find Text",
            icon = " ",
            key = "g",
          },
          { action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
          { action = "qa", desc = " Quit", icon = " ", key = "q" },
        },
        footer = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
        end,
      },
    }

    -- close Lazy and re-open when the dashboard is ready
    if vim.o.filetype == "lazy" then
      vim.cmd.close()
      vim.api.nvim_create_autocmd("User", {
        pattern = "DashboardLoaded",
        callback = function()
          require("lazy").show()
        end,
      })
    end

    return opts
  end,
}
