{ lib, config, ... }:
{
  options.printing.enable = lib.mkEnableOption "CUPS printing";

  config = lib.mkIf config.printing.enable {
    services.printing = {
      enable = true;
      cups-pdf.enable = true;
    };

    security.polkit = {
      enable = true;

      # Passwordless print queue management for users.
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id.indexOf("com.redhat.cups") == 0 && subject.isInGroup("users")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
  };
}
