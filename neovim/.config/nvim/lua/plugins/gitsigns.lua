return {
  "lewis6991/gitsigns.nvim",
  opts = {
    current_line_blame = true,
    attach_to_untracked = true,
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(lhs, rhs, desc, mode)
        local opts = { desc = desc, buffer = bufnr }
        mode = mode or "n"
        vim.keymap.set(mode, lhs, rhs, opts)
      end

      -- Navigation
      map("]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, "Navigate to next change")

      map("[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, "Navigate to previous change")

      -- Actions
      map("<leader>hs", gitsigns.stage_hunk, "Stage hunk")
      map("<leader>hs", function()
        gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Stage hunk", "v")

      map("<leader>hr", gitsigns.reset_hunk, "Reset hunk")
      map("<leader>hr", function()
        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Reset hunk", "v")

      map("<leader>hS", gitsigns.stage_buffer, "Stage buffer")
      map("<leader>hR", gitsigns.reset_buffer, "Reset buffer")
      map("<leader>hp", gitsigns.preview_hunk, "Preview hunk")
      map("<leader>hi", gitsigns.preview_hunk_inline, "Preview hunk inline")

      map("<leader>hb", function()
        gitsigns.blame_line({ full = true })
      end, "Hunk blame")

      map("<leader>hq", gitsigns.setqflist, "Show quickfix list for buffer")
      map("<leader>hQ", function()
        gitsigns.setqflist("all")
      end, "Show quickfix list for project")

      map("<leader>hb", gitsigns.toggle_current_line_blame, "Toggle current line blame")
      map("<leader>hw", gitsigns.toggle_word_diff, "Toggle word diff")

      map("ih", gitsigns.select_hunk, "Select hunk", { "o", "x" })
    end,
  },
}
