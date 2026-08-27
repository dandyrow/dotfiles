{ lib, config, ... }:
{
  options.printing.enable = lib.mkEnableOption "CUPS printing";

  config = lib.mkIf config.printing.enable {
    services.printing = {
      enable = true;
      cups-pdf.enable = true;
    };

    # GNOME auto-enables system-config-printer when printing is on, which adds
    # a "Print Settings" entry to the app menu. Disable it — printer management
    # is accessible via GNOME Settings without this separate tool.
    services.system-config-printer.enable = false;

    # nixpkgs' CUPS module gates cups-pk-helper and its wheel polkit rule on this flag.
    security.polkit.enable = true;
  };
}
