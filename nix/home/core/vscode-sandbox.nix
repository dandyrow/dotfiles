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
    description = ''
      Whether to install the VS Code sandbox tooling (bubblewrap, socat).
      Off by default; WSL enables it explicitly.
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
