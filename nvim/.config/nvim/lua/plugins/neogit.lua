return {
  "NeogitOrg/neogit",
  lazy = true,
  dependencies = {
    {
      "esmuellert/codediff.nvim",
      cmd = "CodeDiff",
      init = function()
        -- Track the tabpage opened by CodeDiff so the keybind can toggle it.
        -- These autocmds are registered immediately (init runs before lazy-load).
        vim.api.nvim_create_autocmd("User", {
          pattern = "CodeDiffOpen",
          callback = function(ev)
            vim.g.codediff_open_tabpage = ev.data and ev.data.tabpage
          end,
        })
        vim.api.nvim_create_autocmd("User", {
          pattern = "CodeDiffClose",
          callback = function()
            vim.g.codediff_open_tabpage = nil
          end,
        })
      end,
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
        local tabpage = vim.g.codediff_open_tabpage
        if tabpage and vim.api.nvim_tabpage_is_valid(tabpage) then
          -- CodeDiff is open; close that tab
          vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(tabpage))
        else
          -- No open CodeDiff view: open one
          vim.cmd.CodeDiff()
        end
      end,
      desc = "Git Diff (toggle)",
    },
  },
}
