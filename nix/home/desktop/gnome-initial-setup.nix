{
  lib,
  osConfig,
  ...
}:
{
  # Marker suppressing gnome-initial-setup re-running each login.
  home.file = lib.mkIf (osConfig.gnome.enable or false) {
    ".config/gnome-initial-setup-done".text = "yes\n";
  };
}
