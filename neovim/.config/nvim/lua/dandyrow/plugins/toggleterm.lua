return {
  "akinsho/toggleterm.nvim",

  opts = {
    open_mapping = [[<C-\>]],
    direction = "float",
    float_opts = {
      border = "curved",
    },
  },

  init = function()
    local Terminal = require("toggleterm.terminal").Terminal

    local htop = Terminal:new({ cmd = "htop", hidden = true })
    function _HTOP_TOGGLE()
      htop:toggle()
    end

    vim.keymap.set(
      "n",
      "<leader>lh",
      "<CMD>lua _HTOP_TOGGLE()<CR>",
      { desc = "Toggle htop float", noremap = true, silent = true }
    )

    local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })
    function _LGIT_TOGGLE()
      lazygit:toggle()
    end

    vim.keymap.set(
      "n",
      "<leader>lg",
      "<CMD>lua _LGIT_TOGGLE()<CR>",
      { desc = "Toggle lazygit float", noremap = true, silent = true }
    )
  end,
}
