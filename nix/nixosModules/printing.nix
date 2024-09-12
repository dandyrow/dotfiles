{ pkgs, lib, config, ... }: {
  options = {
    printing.enable = lib.mkEnableOption "enables printing";
  };

  config = lib.mkIf config.printing.enable {
    services.printing.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
