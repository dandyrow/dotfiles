{
  config,
  lib,
  pkgs,
  # No default, HM always supplies it, null off NixOS.
  osConfig,
  ...
}:
{
  # gpg-agent needs GNUPGHOME in systemd env to use XDG path instead of ~/.gnupg.
  systemd.user = {
    sessionVariables = {
      GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    };
    # gpg requires 700 permissions on its home directory.
    tmpfiles.rules = [
      "d %h/.local/share/gnupg 0700 - - -"
    ];
  };

  # Only add gnupg for standalone HM, NixOS provides it system-wide.
  home.packages = lib.optionals (osConfig == null) [ pkgs.gnupg ];
}
