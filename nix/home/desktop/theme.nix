{
  config,
  pkgs,
  lib,
  ...
}:
{
  catppuccin = {
    enable = true;
    autoEnable = false;
    flavor = "mocha";
    accent = "green";
    firefox = lib.mkIf config.dandyrow.hasDesktop {
      enable = true;
      force = true;
    };
    kitty = lib.mkIf config.dandyrow.hasDesktop {
      enable = true;
    };
  };

  gtk = lib.mkIf config.dandyrow.hasDesktop {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "green";
      };
    };
  };

  dconf.settings = lib.mkIf config.dandyrow.hasDesktop {
    "org/gnome/desktop/interface".icon-theme = lib.mkDefault "Papirus-Dark";
  };
}
