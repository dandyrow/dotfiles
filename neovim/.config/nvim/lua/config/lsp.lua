vim.lsp.enable({
	"lua_ls",
})

vim.diagnostic.config({
	virtual_lines = { current_line = true },
	severity_sort = true,
})

vim.o.winborder = "rounded"
