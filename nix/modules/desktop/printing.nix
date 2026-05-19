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

    security.polkit = {
      enable = true;

      # Passwordless print queue management for admin users.
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id.indexOf("com.redhat.cups") == 0 && subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
  };
}
