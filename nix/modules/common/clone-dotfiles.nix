{ config, pkgs, ... }:
let
  user = config.users.users.${config.dandyrow.primaryUser};
  cloneDotfiles = import ../../lib/clone-dotfiles.nix { inherit (pkgs) lib; };
in
{
  # Runs as root during nixos-anywhere install so the clone lands before first boot with no manual step.
  system.activationScripts.cloneDotfiles = {
    deps = [ "users" ];
    text = cloneDotfiles {
      home = user.home;
      git = "${pkgs.git}/bin/git";
      caCert = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      chownTo = "${user.name}:users";
    };
  };
}
