{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkKit = import ./mk-kit.nix { inherit pkgs; };
  copilotMcpKit = mkKit "copilot-mcp" ../../sbx-kits/copilot-mcp;
in
{
  config = lib.mkIf config.sbx.enable {
    sbx.kits.copilot-mcp = copilotMcpKit;
  };
}
