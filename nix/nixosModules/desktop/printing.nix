{ lib, config, ... }: {
  options = {
    printing = {
      enable = lib.mkEnableOption "printing";
      passwordlessPrinterSetup = lib.mkEnableOption "polkit for passwordless printer setup for users in the print group";
    };
  };

  config = lib.mkIf config.printing.enable {
    services = {
      printing = {
        enable = true;
        cups-pdf.enable = true;
      };

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    security.polkit = lib.mkIf config.printing.passwordlessPrinterSetup {
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
