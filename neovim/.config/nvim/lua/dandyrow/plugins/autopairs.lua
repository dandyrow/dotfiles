return {
  "windwp/nvim-autopairs",

  event = "InsertEnter",

  opts = {
    disable_filetype = {
      "markdown",
    },
    enable_check_bracket_line = true, -- Prevents pair when there's already a closing symbol nearby
    ignored_next_char = "[%w%.]",     -- will ignore alphanumeric and `.` symbol
  },
}
