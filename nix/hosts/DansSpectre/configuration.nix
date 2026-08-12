{ ... }:
{
  users.users.dandyrow.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsxeHA5DWcz/L4A1BpozhL/BTNepsGXfrINkfeZSmvJ dandyrow@WSL" # Work Nix WSL
  ];

  # Coincides with the other hosts by install date, not by sharing — do not consolidate.
  system.stateVersion = "25.11";
}
