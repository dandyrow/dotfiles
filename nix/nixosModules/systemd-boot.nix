{ pkgs, lib, config, ... }: {
  options = {
    systemd-boot.enable = lib.mkEnableOption "enable systemd-boot";
    systemd-boot.timeout = lib.mkOption {
      type = lib.types.int;
      description = "Number of seconds to wait before booting to the first option in the bootloader";
      default = 0;
    };
    systemd-boot.logo = lib.mkEnableOption "enable boot logo";
    systemd-boot.theme = lib.mkOption {
      type = lib.types.str;
      description = "Boot logo (plymouth) theme";
      default = "bgrt";
    };
  };

  config = lib.mkIf config.systemd-boot.enable {
    boot = {
      loader = {
        timeout = config.systemd-boot.timeout;

        systemd-boot = {
          enable = true;
          consoleMode = "max";
          configurationLimit = 14;
        };

        efi.canTouchEfiVariables = true;
      };

      plymouth = lib.mkIf config.systemd-boot.logo {
        enable = true;
        theme = config.systemd-boot.theme;
      };

      # Enable silent boot if logo is enabled
      consoleLogLevel = lib.mkIf config.systemd-boot.logo 0;
      initrd.verbose = lib.mkIf config.systemd-boot.logo false;
      kernelParams = lib.mkIf config.systemd-boot.logo [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };
  };
}
