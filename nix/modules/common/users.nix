{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.dandyrow.primaryUser = lib.mkOption {
    type = lib.types.str;
    default = "dandyrow";
    description = ''
      Login name of the human this machine belongs to. Every site that names the
      user — groups, home directory, password-hash file, Home Manager user —
      follows this option.
    '';
  };

  config.users.users.${config.dandyrow.primaryUser} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "kvm"
    ];
    shell = pkgs.zsh;
    # Hash is injected at install time via nixos-anywhere --extra-files.
    # Never committed in plaintext — see README for the install procedure.
    hashedPasswordFile = "/etc/secrets/${config.dandyrow.primaryUser}-password";
  };
}
