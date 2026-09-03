{
  config,
  configName,
  lib,
  pkgs,
  ...
}:
{
  options.dandyrow.enableVscodeSandbox = lib.mkOption {
    type = lib.types.bool;
    default = configName == "dandyrow@wsl";
    description = ''
      Whether to install the VS Code sandbox tooling (bubblewrap, socat).
      Defaults on for the standalone WSL home, where graphics live in Windows.
    '';
  };

  config.home.packages = lib.mkIf config.dandyrow.enableVscodeSandbox (
    with pkgs;
    [
      bubblewrap
      socat
    ]
  );
}
