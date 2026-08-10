-- No get_language_id: ftdetect/workday.lua already names each filetype after the language ID wdx expects.
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
  root_markers = { "app.amd", ".git" },
}
