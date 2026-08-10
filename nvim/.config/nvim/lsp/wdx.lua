local function app_root(bufnr)
  return vim.fs.root(bufnr, "appManifest.json")
    or vim.fs.root(bufnr, function(name, path)
      return name == "presentation" and #vim.fn.glob(path .. "/presentation/*.amd", true, true) > 0
    end)
    or vim.fs.root(bufnr, ".git")
end

return {
  cmd = { "wdx", "lsp", "--stdio" },
  filetypes = {
    "workday-pmd",
    "workday-pod",
    "workday-amd",
    "workday-smd",
    "workday-pmd-script",
    "workday-wqlquery",
    "workday-graphquery",
    "workday-app-attributes",
    "workday-agent",
    "workday-agentskill",
    "workday-model-businessprocess",
    "workday-model-businessobject",
    "workday-model-securitydomain",
    "workday-model-task",
    "workday-model-attachment",
  },
  root_dir = function(bufnr, on_dir)
    on_dir(app_root(bufnr))
  end,
}
