{
  config,
  lib,
  pkgs,
  ...
}:
let
  servers = lib.mapAttrs (
    _: server: builtins.removeAttrs server [ "tools" ]
  ) config.dandyrow.mcpServers;
in
{
  config = lib.mkIf config.dandyrow.enableVscodeSandbox {
    home.file = {
      ".vscode-server/data/User/mcp.json".text = builtins.toJSON {
        servers = servers // {
          github = {
            type = "http";
            url = "https://api.githubcopilot.com/mcp/";
          };
        };
      };
      ".vscode-server/server-env-setup".text = ''
        export XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome}
        export XDG_CACHE_HOME=${lib.escapeShellArg config.xdg.cacheHome}
        export XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome}
        export XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome}
        export COPILOT_HOME=${lib.escapeShellArg config.home.sessionVariables.COPILOT_HOME}
        export COPILOT_SKILLS_DIRS=${lib.escapeShellArg config.home.sessionVariables.COPILOT_SKILLS_DIRS}
        export NODE_EXTRA_CA_CERTS=${lib.escapeShellArg config.home.sessionVariables.NODE_EXTRA_CA_CERTS}
        export PATH="${
          lib.makeBinPath [
            pkgs.github-copilot-cli
            pkgs.gh
            pkgs.nodejs
          ]
        }:/run/current-system/sw/bin:$PATH"
      '';
    };
  };
}
