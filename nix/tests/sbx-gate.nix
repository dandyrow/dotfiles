{ pkgs }:
pkgs.runCommand "test-sbx-gate"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.git
      pkgs.betterleaks
      pkgs.coreutils
      pkgs.gnused
      pkgs.gnugrep
    ];
  }
  ''
    set -uo pipefail

    mkdir -p "$TMPDIR/hooks"
    cp ${../sbx-kits/agent-gate/pre-push} "$TMPDIR/hooks/pre-push"
    cp ${../sbx-kits/agent-gate/betterleaks-default.toml} "$TMPDIR/hooks/betterleaks-default.toml"
    chmod +x "$TMPDIR/hooks/pre-push"
    hook="$TMPDIR/hooks/pre-push"
    work="$TMPDIR/work"
    zero=0000000000000000000000000000000000000000
    failures=0

    export HOME="$TMPDIR/home"
    export GIT_CONFIG_GLOBAL="$TMPDIR/gitconfig"
    export GIT_CONFIG_NOSYSTEM=1
    mkdir -p "$HOME"
    git config --file "$GIT_CONFIG_GLOBAL" commit.gpgsign false
    git config --file "$GIT_CONFIG_GLOBAL" user.email agent@example.invalid
    git config --file "$GIT_CONFIG_GLOBAL" user.name agent

    # Generated, so the test source carries no token for the repo's own scan to flag.
    fake_token() { printf 'ghp_%s' "$(tr -dc A-Za-z0-9 </dev/urandom | head -c 36)"; }

    reset() {
      rm -rf "$work"
      mkdir -p "$work"
      git init -q --bare -b main "$work/remote.git"
      git init -q -b main "$work/repo"
      cd "$work/repo"
      echo hello >README
      git add README
      git commit -qm init
      git remote add origin "$work/remote.git"
      git push -q --no-verify origin main
      git remote set-head origin main >/dev/null
      git switch -qc feat/x
    }

    # Mirrors git's pre-push stdin: local ref, local sha, remote ref, remote sha.
    invoke() {
      local local_ref="$1" remote_ref="$2" local_sha
      local_sha="$(git rev-parse "$local_ref")"
      printf '%s %s %s %s\n' "$local_ref" "$local_sha" "$remote_ref" "$zero" \
        | bash "$hook" origin
    }

    run_case() {
      local title="$1" expect="$2" got
      shift 2
      reset
      if "$@"; then got=allowed; else got=blocked; fi
      if [[ "$got" == "$expect" ]]; then
        echo "PASS: $title"
      else
        echo "FAIL: $title (expected $expect, got $got)"
        failures=$((failures + 1))
      fi
    }

    clean() {
      echo change >>README
      git commit -qam change
      invoke refs/heads/feat/x refs/heads/feat/x
    }

    repo_config() {
      printf '[extend]\nuseDefault = false\n' >.betterleaks.toml
      echo "token = \"$(fake_token)\"" >cfg.toml
      git add .betterleaks.toml cfg.toml
      git commit -qm config
      invoke refs/heads/feat/x refs/heads/feat/x
    }

    delete_feature() {
      git push -q --no-verify -u origin feat/x
      printf '%s %s %s %s\n' '(delete)' "$zero" refs/heads/feat/x "$zero" \
        | bash "$hook" origin
    }

    delete_default() {
      git switch -q main
      git push -q --no-verify -u origin main
      printf '%s %s %s %s\n' '(delete)' "$zero" refs/heads/main "$zero" \
        | bash "$hook" origin
    }

    default_branch() {
      git switch -qc develop
      echo change >>README
      git commit -qam change
      git push -q --no-verify -u origin develop
      git remote set-head origin develop >/dev/null
      echo change2 >>README
      git commit -qam change2
      invoke refs/heads/develop refs/heads/develop
    }

    to_main() {
      git switch -q main
      echo x >>README
      git commit -qam x
      invoke refs/heads/main refs/heads/main
    }

    secret() {
      echo "token = \"$(fake_token)\"" >cfg.toml
      git add cfg.toml
      git commit -qm cfg
      invoke refs/heads/feat/x refs/heads/feat/x
    }

    secret_fixed() {
      echo "token = \"$(fake_token)\"" >cfg.toml
      git add cfg.toml
      git commit -qm cfg
      git rm -q cfg.toml
      git commit -qm "remove cfg"
      invoke refs/heads/feat/x refs/heads/feat/x
    }

    env_override() {
      printf '[extend]\nuseDefault = false\n' >"$TMPDIR/empty.toml"
      echo "token = \"$(fake_token)\"" >cfg.toml
      git add cfg.toml
      git commit -qm cfg
      BETTERLEAKS_CONFIG="$TMPDIR/empty.toml" invoke refs/heads/feat/x refs/heads/feat/x
    }

    already_pushed() {
      echo "token = \"$(fake_token)\"" >old.toml
      git add old.toml
      git commit -qm old
      git push -q --no-verify -u origin feat/x
      echo change >>README
      git commit -qam change
      invoke refs/heads/feat/x refs/heads/feat/x
    }

    repo_gate() {
      mkdir -p .agents
      printf '#!/bin/sh\nexit %s\n' "$1" >.agents/gate
      chmod +x .agents/gate
      git add .agents
      git commit -qm gate
      invoke refs/heads/feat/x refs/heads/feat/x
    }

    run_case "clean feature branch" allowed clean
    run_case "deleting a feature branch" allowed delete_feature
    run_case "push to refs/heads/main" blocked to_main
    run_case "deleting refs/heads/main" blocked delete_default
    run_case "push to the remote default branch" blocked default_branch
    run_case "repository betterleaks config cannot disable defaults" blocked repo_config
    run_case "secret in a new commit" blocked secret
    run_case "secret added then removed in a later commit" blocked secret_fixed
    run_case "BETTERLEAKS_CONFIG points at an empty config" blocked env_override
    run_case "failing .agents/gate" blocked repo_gate 1
    run_case "passing .agents/gate" allowed repo_gate 0
    run_case "secret already pushed, new clean commit" allowed already_pushed

    if (( failures > 0 )); then
      echo "$failures case(s) failed"
      exit 1
    fi
    touch $out
  ''
