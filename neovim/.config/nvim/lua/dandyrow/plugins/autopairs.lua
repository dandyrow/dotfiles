return {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = function ()
      require('nvim-autopairs').setup {
        disable_filetype = {
          'TelescopePrompt',
          'markdown',
        },
        enable_check_bracket_line = true, -- Prevents pair when there's already a closing symbol nearby
        ignored_next_char = "[%w%.]", -- will ignore alphanumeric and `.` symbol
      }

      -- If you want insert `(` after select function or method item
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
    end
}
