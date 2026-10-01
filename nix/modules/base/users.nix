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
      user — groups, home directory, Home Manager user — follows this option.
    '';
  };

  config = {
    users.users.${config.dandyrow.primaryUser} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "kvm"
      ];
      shell = pkgs.zsh;
      # Hash is injected at install time via nixos-anywhere --extra-files.
      hashedPasswordFile = "/etc/secrets/primary-user-password";
    };

    warnings =
      let
        usersWithInvalidGroups = lib.filter (listEntry: listEntry != null) (
          lib.mapAttrsToList (
            username: user:
            let
              invalidGroups = lib.filter (group: !(config.users.groups ? ${group})) user.extraGroups;
            in
            if invalidGroups != [ ] then "${username}: ${lib.concatStringsSep ", " invalidGroups}" else null
          ) config.users.users
        );
      in
      if usersWithInvalidGroups != [ ] then
        [
          ''
            Users declared with groups in extraGroups that don't exist in users.groups:
            ${lib.concatStringsSep "\n" usersWithInvalidGroups}
          ''
        ]
      else
        [ ];
  };
}
