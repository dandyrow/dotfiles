# Sandbox push gate

The `agent-gate` kit gives every sandbox a pre-push hook that refuses protected
refs, scans the commits being pushed for secrets, then runs the repo's own
`.agents/gate`. It is feedback for the agent, not enforcement. The `main`
ruleset and CI are the enforcement.

## What the hook does

The kit installs `betterleaks` and `pre-push` as root-owned files and runs:

```sh
git config --system core.hooksPath /usr/local/lib/agent-gate/hooks
```

The system setting applies the hook to every repository in the sandbox. A repo
can override it with its own `core.hooksPath`, and a fresh clone does not.

For each ref git is about to push, the hook:

1. Refuses `refs/heads/main` and the remote's default branch.
2. Scans commits with `betterleaks git <local-sha> --not --remotes=<remote>`.
   Only commits the remote does not already have are in range, so a secret
   removed in a later commit is still found.
3. Runs `./.agents/gate` from the repo root when it is executable.

It unsets `BETTERLEAKS_CONFIG` and the related `GITLEAKS_*` variables first, so
the sandbox environment cannot swap in a weaker ruleset.

The gate blocks a normal `git push`. It cannot stop `git push --no-verify`, an
agent that edits the hook after `sudo`, or a local `core.hooksPath` override.
Assume a mistaken agent, not a hostile one. CI runs the same `betterleaks` scan
on every change, and the `main` ruleset requires `ci-ok`.

## Validate the kit

Nix tests the ZIP contents and the hook's behaviour:

```sh
nix build --no-link .#checks.x86_64-linux.sbx-kits
nix build --no-link .#checks.x86_64-linux.sbx-gate
```

`sbx` is unfree and absent from CI, so validate the installed kit on a host that
runs a sandbox:

```sh
sbx kit validate /etc/sbx-kits/agent-gate.zip
```

Then create a sandbox and check the hook is in effect:

```sh
sbx exec <sandbox> git config --system --get core.hooksPath
```

It must print `/usr/local/lib/agent-gate/hooks`.

## CI secret scan

The `secret-scan` job always runs. It has no `changes` gate and no `if`, and it
feeds `ci-ok`. It scans the commits in the run:

| Event | Range |
| --- | --- |
| `pull_request` | `origin/$BASE_REF..HEAD` after fetching the base ref |
| `push` | `$BEFORE..$SHA` |
| Anything else, or a zero `before` | `HEAD` |

It pins `betterleaks` through this flake's lock with
`nix run --inputs-from . nixpkgs#betterleaks`, so CI uses the same nixpkgs
revision as the kit.

The job scans the commits in the run, not every ref. An abandoned
`herdr/.config/herdr/session-history.json` lives in a stash commit and holds
pre-existing low-confidence `generic-password` findings, so a scan with no log
range would fail permanently. The `HEAD` fallback still walks everything
reachable from the checked-out commit; it only skips stashes, other branches,
and dangling objects.

## Maintainer GitHub settings

These settings live on GitHub, not in Nix. Apply them once per repository and
once per host token. They are not applied by any commit in this repo.

### `main` ruleset

List the rulesets and read the `main` one:

```sh
gh api repos/dandyrow/dotfiles/rulesets \
  --jq '.[] | {id, name, target, enforcement}'
gh api repos/dandyrow/dotfiles/rulesets/<id> \
  --jq '{name, bypass_actors, conditions, rules}'
```

Update an existing `main` ruleset. This replaces the rules, removes every
bypass actor, and leaves out `required_signatures`:

```sh
ruleset_id="$(gh api repos/dandyrow/dotfiles/rulesets \
  --jq '.[] | select(.name == "main") | .id')"
gh api --method PUT "repos/dandyrow/dotfiles/rulesets/$ruleset_id" --input - <<'JSON'
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [{ "context": "ci-ok" }]
      }
    },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}
JSON
```

If no `main` ruleset exists, use the same JSON with
`gh api --method POST repos/dandyrow/dotfiles/rulesets --input -`.

The pull request rule requires a PR but no approvals, so an agent can merge its
own PR. Expected state: `bypass_actors` is `[]`, the rules are `deletion`,
`non_fast_forward`, `required_status_checks` with `ci-ok`, and `pull_request`,
and `required_signatures` is absent.

### Secret scanning and push protection

Read the current state:

```sh
gh api repos/dandyrow/dotfiles \
  --jq '.security_and_analysis | {secret_scanning, secret_scanning_push_protection}'
```

Enable both:

```sh
gh api --method PATCH repos/dandyrow/dotfiles --input - <<'JSON'
{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
JSON
```

Both must report `"enabled"`. Private repos on GitHub Free cannot use rulesets
or push protection; there the in-VM gate is the only check.

### Workflows "No access"

Agents can open and merge their own PRs, so their token must not be able to
rewrite `.github/workflows/`. Fine-grained PATs have no read-only choice for
Workflows. Set it to **No access**.

GitHub has no REST endpoint that lists or edits personal access tokens, so this
step is manual:

1. Open <https://github.com/settings/personal-access-tokens>.
2. Edit the host token, for example `sbx-WSL`.
3. Under Repository permissions, set Workflows to **No access**.
4. Save.

The classic WSL PAT has no `workflow` scope. Check it on the host:

```sh
gh auth status
```

`Token scopes` must not include `workflow`.

For an App-backed host, verify the App permissions:

```sh
gh api apps/<app-slug> --jq '.permissions'
```

The output must not contain `workflows`. The App manifest sets no Workflows
permission. Change it under
<https://github.com/settings/apps/<app-slug>/permissions> if it ever appears.

The repo setting from
`gh api repos/dandyrow/dotfiles/actions/permissions/workflow` applies to
`GITHUB_TOKEN`, not to PATs or Apps. Do not rely on it for agent credentials.
