{ pkgs, lib, config, ... }: {
  options = {
    systemd-boot.enable = lib.mkEnableOption "enable systemd-boot";
  };

  config = lib.mkIf config.systemd-boot.enable {
    boot.loader.timeout = 5;
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.consoleMode = "max";
    boot.loader.systemd-boot.configurationLimit = 14;

    boot.loader.efi.canTouchEfiVariables = true;
  };
}
