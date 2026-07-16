{ ... }:
{
  # $HOME-literal, not XDG vars: those are interactive-zsh-only, and NixOS rewrites $HOME to pam_env's @{HOME}.
  # Trade-off: pam_env covers login/PAM sessions but not system-level systemd units started outside one.
  environment.sessionVariables = {
    COPILOT_HOME = "$HOME/.config/copilot";
    COPILOT_SKILLS_DIRS = "$HOME/.local/share/agents/skills";
  };
}
