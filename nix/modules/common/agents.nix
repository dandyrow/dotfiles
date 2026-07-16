{ ... }:
{
  # $HOME-literal, not XDG vars: those are interactive-zsh-only, and NixOS rewrites $HOME to pam_env's @{HOME}.
  environment.sessionVariables = {
    COPILOT_HOME = "$HOME/.config/copilot";
    COPILOT_SKILLS_DIRS = "$HOME/.local/share/agents/skills";
  };
}
