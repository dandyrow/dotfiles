{ lib, config, ... }:
{
  options = {
    doas = {
      enable = lib.mkDefault true;
    };
  };

  config = lib.mkIf config.doas.enable {
    security = {
      sudo.enable = false;

      doas = {
        enable = true;
        extraRules = [
          {
            groups = lib.mkDefault [ "wheel" ];
            persist = true;
          }
        ];
      };
    };
  };
}
