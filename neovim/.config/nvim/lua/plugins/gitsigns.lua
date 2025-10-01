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
      map("]h", function()
        gitsigns.nav_hunk({ "next" })
      end, "Navigate to next hunk")

      map("[h", function()
        gitsigns.nav_hunk({ "prev" })
      end, "Navigate to previous hunk")

      -- Actions
      map("<leader>hs", gitsigns.stage_hunk, "Stage hunk")
      map("<leader>hs", function()
        gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Stage hunk", "v")

      map("<leader>hr", gitsigns.reset_hunk, "Reset hunk")
      map("<leader>hr", function()
        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Reset hunk")

      map("<leader>hS", gitsigns.stage_buffer, "Stage buffer")
      map("<leader>hR", gitsigns.reset_buffer, "Reset buffer")
      map("<leader>hp", gitsigns.preview_hunk, "Preview hunk")
      map("<leader>hq", gitsigns.setqflist, "Show quickfix list")
      map("<leader>hw", gitsigns.toggle_word_diff, "Toggle word diff")

      map("<leader>hb", function()
        gitsigns.blame_line({ full = true })
      end, "Hunk blame")

      map("ih", gitsigns.select_hunk, "Select hunk", { "o", "x" })
    end,
  },
}
