{ ... }:
{
  users.users.dandyrow = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Hash is injected at install time via nixos-anywhere --extra-files.
    # Never committed in plaintext — see README for the install procedure.
    hashedPasswordFile = "/etc/secrets/dandyrow-password";
  };
}
