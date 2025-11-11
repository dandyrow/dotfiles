return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  init = function()
    local function set_keymaps()
      vim.keymap.set({ "n", "t", "i" }, "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
      vim.keymap.set({ "n", "t", "i" }, "<C-j>", "<cmd>TmuxNavigateDown<cr>")
      vim.keymap.set({ "n", "t", "i" }, "<C-k>", "<cmd>TmuxNavigateUp<cr>")
      vim.keymap.set({ "n", "t", "i" }, "<C-l>", "<cmd>TmuxNavigateRight<cr>")
    end

    set_keymaps()

    vim.api.nvim_create_autocmd("TermOpen", {
      callback = set_keymaps,
    })

    vim.api.nvim_create_autocmd("InsertEnter", {
      callback = set_keymaps,
    })
  end,
}
