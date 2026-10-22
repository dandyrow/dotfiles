{ lib, pkgs }:
let
  kit =
    (lib.evalModules {
      modules = [
        ../modules/base/sbx-mcp.nix
        {
          options.sbx = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            kits = lib.mkOption {
              type = lib.types.attrsOf lib.types.package;
              default = { };
            };
          };
          config.sbx.enable = true;
        }
      ];
      specialArgs = { inherit pkgs; };
    }).config.sbx.kits.copilot-mcp;
in
pkgs.runCommand "test-sbx-mcp" { } ''
  ${pkgs.unzip}/bin/unzip -p ${kit} spec.yaml | ${pkgs.gnugrep}/bin/grep -qx 'name: copilot-mcp'
  ${pkgs.unzip}/bin/unzip -p ${kit} spec.yaml | ${pkgs.gnugrep}/bin/grep -qx 'kind: mixin'
  ${pkgs.unzip}/bin/unzip -p ${kit} files/home/.copilot/mcp-config.json \
    | ${pkgs.jq}/bin/jq -e '.mcpServers["mcp-gateway"] | .type == "http" and .url == "http://mcp-gateway.docker.internal/mcp" and .headers.Authorization == "Bearer proxy-managed" and .tools == ["*"]'
  touch $out
''
