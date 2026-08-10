-- Filetypes mirror wdx's LSP language IDs: Neovim sends filetype as languageId, which wdx trusts over the file path.
vim.filetype.add({
  extension = {
    pmd = "workday-pmd",
    pod = "workday-pod",
    amd = "workday-amd",
    smd = "workday-smd",
    script = "workday-pmd-script",
    wqlquery = "workday-wqlquery",
    graphquery = "workday-graphquery",
    attributes = "workday-app-attributes",
    agent = "workday-agent",
    agentskill = "workday-agentskill",
    businessprocess = "workday-model-businessprocess",
    businessobject = "workday-model-businessobject",
    securitydomain = "workday-model-securitydomain",
    task = "workday-model-task",
    attachment = "workday-model-attachment",
    orchestration = "json",
    suborchestration = "json",
  },
  filename = {
    ["app_attribute_extensions.json"] = "workday-app-attributes",
  },
  pattern = {
    [".*%.pmd%.json"] = "workday-pmd",
  },
})
