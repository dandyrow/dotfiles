{
  config,
  lib,
  ...
}:
lib.mkIf config.dandyrow.hasDesktop {
  # Suppress CLI .desktop entries from whatever desktop launcher is present.
  xdg.desktopEntries = {
    btop = {
      name = "btop++";
      noDisplay = true;
    };
    cups = {
      name = "Manage Printing";
      noDisplay = true;
    };
    nvim = {
      name = "Neovim";
      noDisplay = true;
    };
    yazi = {
      name = "Yazi";
      noDisplay = true;
    };
  };
}
