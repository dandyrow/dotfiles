{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = config.dandyrow;
  # Standalone has no osConfig, so the work flag marks the WSL home there.
  onWsl = if cfg.isStandalone then cfg.isWork else (osConfig.wsl.enable or false);

  canvasKitMcp = pkgs.writeShellApplication {
    name = "canvas-kit-mcp";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      export npm_config_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/npm"
      mkdir -p "$npm_config_cache"
      exec npx -y @workday/canvas-kit-mcp "$@"
    '';
  };
in
{
  config = lib.mkIf onWsl {
    home.packages = [ canvasKitMcp ];
  };
}
