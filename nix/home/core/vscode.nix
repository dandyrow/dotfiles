{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.dandyrow.enableVscodeSandbox = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to install VS Code remote sandbox support on this host.";
  };

  config = lib.mkIf config.dandyrow.enableVscodeSandbox {
    home.packages = with pkgs; [
      bubblewrap
      socat
      slirp4netns
    ];

    xdg.dataFile."vscode-server/data/User/mcp.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/vscode/.local/share/vscode-server/data/User/mcp.json";
    home.file.".vscode-server/server-env-setup".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/vscode/.vscode-server/server-env-setup";
  };
}
