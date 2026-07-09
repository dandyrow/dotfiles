{ config, lib, ... }:
{
  options = {
    doas = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      adminGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "wheel" ];
      };
    };
  };

  config = lib.mkIf config.doas.enable {
    security = {
      sudo.enable = lib.mkDefault false;

      doas = {
        enable = true;
        extraRules = [
          {
            groups = config.doas.adminGroups;
            persist = true;
          }
        ];
      };
    };
  };
}
