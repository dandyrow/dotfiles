{
  config,
  lib,
  pkgs,
  ...
}:
let
  copilotMcpKit = pkgs.runCommand "copilot-mcp.zip" { nativeBuildInputs = [ pkgs.zip ]; } ''
    cd ${../../sbx-kits/copilot-mcp}
    zip -qrX $out spec.yaml files
  '';
in
{
  config = lib.mkIf config.sbx.enable {
    sbx.kits.copilot-mcp = copilotMcpKit;
  };
}
