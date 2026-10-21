{
  lib,
  homeConfigurations,
}:
let
  work = homeConfigurations."dandyrow@wsl".config;
  personal = homeConfigurations."dandyrow@x86_64-linux".config;
  parse = text: builtins.fromJSON (builtins.unsafeDiscardStringContext text);
  cli = parse work.xdg.configFile."copilot-managed/mcp-config.json".text;
  editor = parse work.home.file.".vscode-server/data/User/mcp.json".text;
  settings = parse work.xdg.configFile."copilot-managed/settings.json".text;
  sandbox =
    (lib.importJSON ../../vscode/windows-settings.json)
    ."chat.agent.sandbox.fileSystem.userConfiguredPaths";
in
lib.runTests {
  testWorkServers = {
    expr = builtins.attrNames cli.mcpServers;
    expected = [
      "atlassian"
      "canvas-kit-mcp"
      "context7"
      "wdx"
    ];
  };
  testGithubUsesBuiltinOnlyInCli = {
    expr = editor.servers.github;
    expected = {
      type = "http";
      url = "https://api.githubcopilot.com/mcp/";
    };
  };
  testEditorSharesCliServers = {
    expr = builtins.removeAttrs editor.servers [ "github" ];
    expected = lib.mapAttrs (_: server: builtins.removeAttrs server [ "tools" ]) cli.mcpServers;
  };
  testPinnedLocalCommands = {
    expr = map (name: lib.hasPrefix "/nix/store/" cli.mcpServers.${name}.command) [
      "canvas-kit-mcp"
      "wdx"
    ];
    expected = [
      true
      true
    ];
  };
  testWdxIsWorkOnly = {
    expr = personal.dandyrow.mcpServers ? wdx;
    expected = false;
  };
  testCopilotStateIsOutsideCheckout = {
    expr = work.home.sessionVariables.COPILOT_HOME;
    expected = "${work.xdg.stateHome}/copilot";
  };
  testHookUsesStateDirectory = {
    expr = (builtins.head settings.hooks.SessionStart).bash;
    expected = "bash '${work.xdg.stateHome}/copilot/hooks/herdr-agent-state.sh'";
  };
  testCopilotCompatibilityLinkIsDeclared = {
    expr = work.home.file ? ".config/copilot";
    expected = true;
  };
  testWslEnvironment = {
    expr = lib.hasInfix "COPILOT_HOME=" work.home.file.".vscode-server/server-env-setup".text;
    expected = true;
  };
  testPersonalHasNoRemoteEditorConfig = {
    expr = personal.home.file ? ".vscode-server/data/User/mcp.json";
    expected = false;
  };
  testNixSandboxGrants = {
    expr = sandbox.readonlyPaths;
    expected = [
      "/nix/store"
      "/etc/profiles"
      "/run/current-system"
      "/nix/var/nix/profiles"
      "/nix/var/nix/daemon-socket"
    ];
  };
}
