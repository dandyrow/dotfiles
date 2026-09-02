{
  config,
  lib,
  ...
}:
lib.mkIf config.dandyrow.hasDesktop {
  programs.kitty = {
    enable = true;
    # Nerd font ships system-wide via the zsh module, so font.package stays unset.
    font = {
      name = "DejaVuSansM Nerd Font Mono";
      size = 14;
    };
    mouseBindings = {
      "ctrl+left click" = "ungrabbed mouse_handle_click selection link prompt";
    };
  };
}
