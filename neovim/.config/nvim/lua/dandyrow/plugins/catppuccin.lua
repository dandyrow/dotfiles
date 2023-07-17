return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function ()
    require('catppuccin').setup {
      show_end_of_buffer = true,
      term_colors = true,
      dim_inactive = {
        enabled = true,
        shade = 'dark',
        percentage = 0.15,
      },
      integrations = {
        nvimtree = true,
        telescope = {
          enabled = true,
        },
        treesitter = true,
      },
    }

    -- Safely activate colourscheme
    local status_ok, _ = pcall(vim.cmd, 'colorscheme catppuccin')
    if not status_ok then
      vim.notify('colorscheme catppuccin not found!')
      return
    end
  end,
}
