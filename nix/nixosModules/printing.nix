{ pkgs, lib, config, ... }: {
  options = {
    printing.enable = lib.mkEnableOption "enables printing";
    passwordless-printer-setup.enable = lib.mkEnableOption "enables polkit for passwordless printer setup for users in the print group";
  };

  config = lib.mkIf config.printing.enable {
    services.printing = {
      enable = true;
      cups-pdf.enable = true;
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    security.polkit = lib.mkIf config.passwordless-printer-setup.enable {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.opensuse.cupspkhelper.mechanism.all-edit" && subject.isInGroup("print")) {
            return polkit.Result.YES;
          }
          });
      '';
    };
  };
}
