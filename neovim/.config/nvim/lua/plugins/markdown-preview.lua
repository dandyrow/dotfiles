return {
	"iamcco/markdown-preview.nvim",
  build = ":call mkdp#util#install()",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown" },
	keys = {
		{ "<leader>pm", "<CMD>MarkdownPreviewToggle<CR>", desc = "Toggle markdown preview" },
	},
}
