local enabled_filetypes = {
  css = true,
  scss = true,
  sass = true,
  less = true,
  html = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  vue = true,
  svelte = true,
}

return {
  "brenoprata10/nvim-highlight-colors",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    render = "virtual",
    enable_tailwind = true,
    exclude_buffer = function(bufnr)
      return not enabled_filetypes[vim.bo[bufnr].filetype]
    end,
  },
}
