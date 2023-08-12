return {
  'lewis6991/gitsigns.nvim',

  opts = {
    current_line_blame = true,
    numhl = true,

    on_attach = function (bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then return ']c' end
        vim.schedule(function() gs.next_hunk() end)
        return '<Ignore>'
      end, {desc = 'Next git hunk', expr=true})

      map('n', '[c', function()
        if vim.wo.diff then return '[c' end
        vim.schedule(function() gs.prev_hunk() end)
        return '<Ignore>'
      end, {desc = 'Previous git hunk', expr=true})

      -- Actions
      map('n', '<leader>hs', gs.stage_hunk, {desc = 'Stage git hunk'})
      map('n', '<leader>hr', gs.reset_hunk, {desc = 'Reset git hunk'})
      map('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, {desc = 'Stage git hunk'})
      map('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, {desc = 'Reset git hunk'})
      map('n', '<leader>hS', gs.stage_buffer, {desc = 'Stage git buffer'})
      map('n', '<leader>hu', gs.undo_stage_hunk, {desc = 'Undo stage git hunk'})
      map('n', '<leader>hR', gs.reset_buffer, {desc = 'Reset git buffer'})
      map('n', '<leader>hp', gs.preview_hunk, {desc = 'Preview git hunk'})
      map('n', '<leader>hb', function() gs.blame_line{full=true} end, {desc = 'Git blame line'})
      map('n', '<leader>tb', gs.toggle_current_line_blame, {desc = 'Toggle current line blame'})
      map('n', '<leader>hd', gs.diffthis, {desc = 'Show git diff'})
      map('n', '<leader>hD', function() gs.diffthis('~') end, {desc = 'Show git diff ~'})
      map('n', '<leader>td', gs.toggle_deleted, {desc = 'Toggle deleted (git)'})

      -- Text object
      map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', {desc = 'Select hunk'})
    end
  },
}
