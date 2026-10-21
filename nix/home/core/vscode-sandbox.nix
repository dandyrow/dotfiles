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
      Whether to provision VS Code remote configuration and sandbox tooling.
      Off by default; WSL enables it explicitly.
    '';
  };

  config.home.packages = lib.mkIf config.dandyrow.enableVscodeSandbox (
    with pkgs;
    [
      bubblewrap
      socat
      slirp4netns
    ]
  );
}
