# VS Code sandbox bwrap cannot bind the per-user profile symlink chain and builds its binds from the resolved PATH.
if [[ -n $VSCODE_RESOLVING_ENVIRONMENT ]]; then
  path=(${path:#/etc/profiles/per-user/*})
# Terminals inherit the stripped PATH and skip set-environment, so restore it for interactive use.
elif [[ -o interactive && $TERM_PROGRAM == vscode && -d /etc/profiles/per-user/$USER/bin ]]; then
  path=(${path:#/etc/profiles/per-user/$USER/bin} /etc/profiles/per-user/$USER/bin)
fi
