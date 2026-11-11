{
  config,
  lib,
  ...
}:
{
  options.dandyrow.enableVscodeSandbox = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to link VS Code remote sandbox config on this host.";
  };

  config = lib.mkIf config.dandyrow.enableVscodeSandbox {
    home.file.".vscode-server/data/User/mcp.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/vscode/.vscode-server/data/User/mcp.json";
    home.file.".vscode-server/server-env-setup".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/vscode/.vscode-server/server-env-setup";
  };
}
