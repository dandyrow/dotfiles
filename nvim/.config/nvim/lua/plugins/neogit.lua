return {
  "NeogitOrg/neogit",
  lazy = true,
  dependencies = {
    {
      "esmuellert/codediff.nvim",
      cmd = "CodeDiff",
    },
    "folke/snacks.nvim",
  },
  cmd = "Neogit",
  opts = {
    graph_style = "unicode",
    process_spinner = true,
    kind = "floating",
    commit_editor = { kind = "tab", staged_diff_split_kind = "vsplit" },
    rebase_editor = { kind = "tab" },
  },
  keys = {
    {
      "<leader>gs",
      function()
        local neogit = require("neogit")

        neogit.open({ cwd = vim.fn.systemlist("git -C " .. vim.fn.expand("%:p:h") .. " rev-parse --show-toplevel")[1] })
      end,
      desc = "Git Status",
    },
    {
      "<leader>gd",
      function()
        if require("diffview.lib").get_current_view() then
          -- Current tabpage is a Diffview; close it
          vim.cmd.DiffviewClose()
        else
          -- No open Diffview exists: open a new one
          vim.cmd.DiffviewOpen()
        end
      end,
      desc = "Git Diff",
    },
  },
}
