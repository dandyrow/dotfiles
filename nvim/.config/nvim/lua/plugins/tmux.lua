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
    vim.keymap.set({ "n", "t", "i" }, "<c-h>", "<cmd>TmuxNavigateLeft<cr>")
    vim.keymap.set({ "n", "t", "i" }, "<c-j>", "<cmd>TmuxNavigateDown<cr>")
    vim.keymap.set({ "n", "t", "i" }, "<c-k>", "<cmd>TmuxNavigateUp<cr>")
    vim.keymap.set({ "n", "t", "i" }, "<c-l>", "<cmd>TmuxNavigateRight<cr>")
  end,
}
