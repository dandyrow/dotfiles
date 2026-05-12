{ config, pkgs, ... }:
let
  user = config.users.users.dandyrow;
in
{
  # Clone the dotfiles repo to ~/.dotfiles during system activation.
  # This runs as part of nixos-anywhere install, before first boot, so network
  # is available and no manual step is required after installation.
  system.activationScripts.cloneDotfiles = {
    deps = [ "users" ];
    text = ''
      if [ ! -d "${user.home}/.dotfiles" ]; then
        GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
          ${pkgs.git}/bin/git clone \
            https://github.com/dandyrow/dotfiles.git \
            "${user.home}/.dotfiles"
        chown -R ${user.name}:users "${user.home}/.dotfiles"
      fi
    '';
  };
}
