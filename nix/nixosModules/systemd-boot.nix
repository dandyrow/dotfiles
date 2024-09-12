{ pkgs, lib, config, ... }: {
  options = {
    systemd-boot.enable = lib.mkEnableOption "enable systemd-boot";
    systemd-boot.timeout = lib.mkOption {
      type = lib.types.int;
      description = "Number of seconds to wait before booting to the first option in the bootloader";
      default = 0;
    };
  };

  config = lib.mkIf config.systemd-boot.enable {
    boot.loader.timeout = config.systemd-boot.timeout;
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.consoleMode = "max";
    boot.loader.systemd-boot.configurationLimit = 14;

    boot.loader.efi.canTouchEfiVariables = true;
  };
}
