{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.sbx = {
    enable = lib.mkEnableOption "Docker Sandboxes (sbx)";

    kits = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = "sbx kits to install as ZIP bundles under /etc/sbx-kits.";
    };
  };

  config = lib.mkIf config.sbx.enable {
    environment.systemPackages = [ pkgs.docker-sbx ];

    environment.etc = lib.mapAttrs' (
      name: drv: lib.nameValuePair "sbx-kits/${name}.zip" { source = drv; }
    ) config.sbx.kits;
  };
}
