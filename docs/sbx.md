# Sandboxed agents

`agent-sbx <opencode|copilot>` runs an agent in a docker-sbx microVM. The VM
gets a clone of the repository, no host mounts, no real GitHub token, and a
pre-push gate. The host keeps the credentials and MCP OAuth tokens; sbx's proxy
swaps placeholders for real values before forwarding a request.

The setup is Nix-managed except for per-host state: GitHub App registration,
sbx secrets, MCP registrations, network policy, and the SSH-agent setting. The
checklist below lists every one-time action.

## Launch

```sh
agent-sbx opencode
agent-sbx copilot
agent-sbx opencode -- --model github-copilot/claude-sonnet-4
```

Arguments after `--` go to the agent. The launcher resolves the main checkout
with `git rev-parse --path-format=absolute --git-common-dir`, so it works from a
linked worktree. The sandbox is named `<agent>-<repo basename>`.

On first use the launcher creates the sandbox with:

- `--clone` from the main checkout.
- The kits for the host and agent.
- The identity variables for the host.
- `--static-mcp` built from `sbx mcp ls --json`.
- A per-sandbox GitHub App mint when WSL is running a personal repository.

It then changes to the main checkout and runs `sbx run` with the remaining
arguments.

When a sandbox with that name already exists, the launcher reattaches. It passes
only the name and identity variables. Create-only flags are not repeated. The
sandbox keeps the kits and MCP set it was created with. To apply a changed kit or
MCP set, remove and recreate it:

```sh
sbx rm <sandbox>
agent-sbx <agent>
```

`sbx rm` deletes commits that were never pushed.

| Kit | Host | Agent | Purpose |
| --- | --- | --- | --- |
| `agent-gate` | all | all | Pre-push hook and `betterleaks` |
| `corp-ca` | WSL, when `/etc/nixos/corp.pem` exists | all | Trust the Zscaler CA |
| `opencode-copilot` | WSL | opencode | Copilot models through the host token |
| `copilot-mcp` | all | copilot | MCP client configuration |

The launcher and the identity scripts read these Home Manager options from
`nix/home/core/sbx-identity.nix`:

| Option | Meaning |
| --- | --- |
| `dandyrow.sbxIdentity.enable` | sbx is enabled on this host |
| `dandyrow.sbxIdentity.isWsl` | personal-repo routing and file backend apply |
| `dandyrow.sbxIdentity.gitIdentity.name` | `GIT_AUTHOR_NAME` and `GIT_COMMITTER_NAME` |
| `dandyrow.sbxIdentity.gitIdentity.email` | `GIT_AUTHOR_EMAIL` and `GIT_COMMITTER_EMAIL` |
| `dandyrow.sbxIdentity.github.mintCommand` | command for `sbx secret set --command` |
| `dandyrow.sbxIdentity.github.backend` | `file` or `keyring` |
| `dandyrow.sbxIdentity.github.appName` | App name used in registration messages |

## Per-host checklist

Run the steps in order after the host has the current configuration.

| Step | DansSpectre | New-H0Ryzen | WSL |
| --- | --- | --- | --- |
| Rebuild | `doas nixos-rebuild switch --flake .#DansSpectre` | `doas nixos-rebuild switch --flake .#New-H0Ryzen` | `doas nixos-rebuild switch --flake .#WSL --impure` |
| Sign in to Docker | `sbx login` | `sbx login` | `sbx login` |
| Network policy | `sbx policy init allow-all` | `sbx policy init allow-all` | `sbx policy reset` then `sbx policy init allow-all` |
| SSH agent forwarding | disable | disable | disable |
| GitHub App | register and install | register and install | register and install |
| Global `github` secret | App mint | App mint | classic PAT |
| Global `copilot` secret | not used | not used | fine-grained PAT |
| `opencode-copilot` secret and binding | not used | not used | set |
| Context7 MCP | register | register | register |
| Atlassian and Canvas Kit MCP | not used | not used | register |
| Remove old sandboxes | all pre-wrapper | all pre-wrapper | all pre-wrapper, including `copilot-.dotfiles` |
| End-to-end verification | run | run | run |

The rebuild installs `agent-sbx`, `sbx-github-mint`, `sbx-github-app-register`,
and the kits. On WSL it also installs the `canvas-kit-mcp` wrapper.

### Common host steps

```sh
sbx login

# Personal hosts only.
sbx policy init allow-all

# WSL only: the host already has a Balanced policy from the old setup.
sbx policy reset
sbx policy init allow-all

sbx settings set ssh.agentForwardingEnabled false && sbx daemon restart
```

`sbx policy reset` deletes the local policy store and stops the daemon. Running
sandboxes stop, and it prompts unless you pass `--force`.

### Remove pre-wrapper sandboxes

Sandboxes created before this setup ran without `--clone` and without the kits.
`sbx ls --json` does not report clone mode, so the launcher cannot detect them.
List and remove every sandbox that predates the launcher:

```sh
sbx ls
sbx rm <sandbox>
```

WSL has one known case: `copilot-.dotfiles` already has the launcher's naming
scheme but was created without `--clone` or kits. Remove it too.

`sbx rm` deletes the sandbox, its unpushed commits, its scoped secrets, and the
`sandbox-<name>` git remote on the host. Add `--force` if it refuses a non-TTY
confirmation. Recreate with `agent-sbx` afterwards.

Once the host App works, delete the old `sbx-DansSpectre` and
`sbx-New-H0Ryzen` personal access tokens in GitHub.

## Credentials and identity

Sandboxed agents never hold a real GitHub token. The host stores one credential
per host, sbx swaps a placeholder for the real value inside its proxy, and the
VM only sees the placeholder. Git commits use a fixed bot identity so a human can
review what the agent did.

### Where credentials live

| Host | GitHub App ID and private key | sbx secret store |
| --- | --- | --- |
| DansSpectre, New-H0Ryzen | GNOME Keyring, service `sbx-github-app`, attributes `host=<host>` and `kind=app-id` or `kind=private-key` | GNOME Keyring, `login` collection, `service:group=com.docker.sandboxes` |
| WSL | `$XDG_CONFIG_HOME/sbx/github-app-id` and `$XDG_CONFIG_HOME/sbx/github-app.pem`, mode 0600 | age-encrypted files under `$XDG_CONFIG_HOME/com.docker.sandboxes/` |

`XDG_CONFIG_HOME` defaults to `$HOME/.config`. The file store on WSL has a
constant scrypt password that ships in the sbx binary, so file permissions do
the real work there. This matches the risk already accepted for the host `gh`
token in `~/.config/gh/hosts.yml`.

sbx picks its backend itself. It tries Secret Service over D-Bus first and falls
back to the file store when no keyring owns `org.freedesktop.secrets`. Keep the
CLI and the daemon in the same session and the same `XDG_CONFIG_HOME`.

sbx has no systemd unit. The CLI starts the daemon on first use, and the daemon
keeps the environment of that user session: D-Bus, GNOME Keyring, and
`XDG_CONFIG_HOME`. Start sbx from a terminal in the desktop session. After a
reboot, the first `sbx` or `agent-sbx` command starts the daemon again. A daemon
started over SSH or in another session may not see the keyring.

### Git identity

The launcher passes the identity as four `-e` flags:

| Host | Author and committer |
| --- | --- |
| WSL | `Copilot <198982749+Copilot@users.noreply.github.com>` |
| DansSpectre, New-H0Ryzen | `opencode-agent[bot] <219766164+opencode-agent[bot]@users.noreply.github.com>` |

The flags are:

```sh
-e GIT_AUTHOR_NAME=<name>
-e GIT_AUTHOR_EMAIL=<email>
-e GIT_COMMITTER_NAME=<name>
-e GIT_COMMITTER_EMAIL=<email>
```

The values come from the Home Manager options
`dandyrow.sbxIdentity.gitIdentity.name` and
`dandyrow.sbxIdentity.gitIdentity.email`. On WSL every sandbox commits as
Copilot, including Kainos sandboxes. On the personal hosts the identity matches
the OpenCode Agent App owned by `anomalyco`.

### GitHub identity per host

Each host has its own GitHub App, named `dandyrow-agent-<host>`. The App owns the
installation token. The installation covers all repositories owned by
`dandyrow`. App permissions are:

- Read and write: Contents, Pull requests, Issues, Actions, Commit statuses.
- Read: Metadata.
- No Workflows and no Administration.

A token minted by the App lasts one hour. `sbx secret set --command` stores the
command text and reruns it once the cached value is 55 minutes old, so the proxy
never sends a token older than that.

The App shows up as `<app>[bot]` on GitHub. The App's own noreply address is not
used for commits because the git identity above is fixed per host.

### Per-host secrets

#### DansSpectre and New-H0Ryzen

The global `github` secret is the App mint. There is no `copilot` secret because
neither host has a Copilot seat.

```sh
sbx secret set github --command 'sbx-github-mint'
```

#### WSL

The global `github` secret stays a token acting as `dandyrow` because Kainos
repositories cannot take a third-party App. It is a classic PAT with only the
`repo` scope, no `workflow` scope, and no expiration. Authorize it for
`KainosSoftwareLtd` under **Configure SSO**:

```sh
sbx secret set github
```

Paste the classic PAT at the prompt. Do not pass `--token`; it lands in shell
history.

Copilot CLI gets its own secret. The token is a fine-grained PAT owned by
`dandyrow` with only Account, Copilot requests. Classic PATs are rejected by
Copilot CLI, which is why WSL needs this exception:

```sh
sbx secret set copilot
```

Paste the fine-grained PAT at the prompt.

A sandbox for a personal repository on WSL overrides `github` for that sandbox
only, so it acts as the App instead of the Kainos PAT:

```sh
sbx secret set github --sandbox <sandbox> --command 'sbx-github-mint'
```

The launcher does this on create. The override works before or after
`sbx create`, takes effect on the next request without a restart, and
`sbx rm` deletes it. The global `github` secret must still exist at create time
because it sets the `GH_TOKEN` placeholder.

Personal and Kainos routing is decided from the repository origin. A `dandyrow`
origin gets the App override. Any other origin is Kainos and keeps the global
PAT. With no origin, a path under `~/Projects/work/` is Kainos; anything else is
personal.

### Register a host App

Run once per host, from a terminal in the user session:

```sh
sbx-github-app-register
```

The command builds a manifest with the permissions above, starts a callback
server on `127.0.0.1:47831`, and prints a `http://localhost:47831/` URL. Open it
in a browser logged in as `dandyrow`. The page posts the manifest to GitHub.
Click **Create GitHub App** if the form does not submit itself.

GitHub redirects to the local callback with a one-use code. The command then
calls `POST /app-manifests/<code>/conversions`, stores the returned App ID and
private key in the host backend, and prints the App installation URL:

```text
https://github.com/apps/<app>/installations/new
```

Install the App on all repositories. The manifest flow returns the private key
only once. If the browser cannot reach the callback, copy the `code` query
parameter from the failed callback URL and rerun:

```sh
sbx-github-app-register --code <code>
```

The code expires after one hour. Use `--force` only when replacing a host's
credentials. Without it, the command refuses to overwrite an existing App key.

The App name defaults to `dandyrow-agent-<lowercase host name>`. Override it with
`--app-name`, the owner with `--owner`, and the callback port with `--port`.
GitHub has no API for uploading an App logo. Upload the robot glyph with a host
letter by hand if the App should not show the owner's avatar.

### Mint an installation token

```sh
sbx-github-mint
```

The command reads the host App ID and private key, builds an RS256 JWT with
`iat` set to 60 seconds ago and `exp` set to 10 minutes from now, lists
`/app/installations`, and exchanges the JWT for an installation token. It prints
only the token to stdout so `sbx secret set --command` can consume it. Missing
credentials, a missing installation, or a failed GitHub request writes an
actionable error to stderr and exits nonzero.

Run it by hand to check registration:

```sh
sbx-github-mint | cut -c1-4
```

The prefix is `ghs_`. Do not print the whole token.

### opencode Copilot on WSL

WSL opencode uses its own Copilot OAuth token through the `opencode-copilot`
mixin kit. The kit claims `api.githubcopilot.com` from the `github` service, so
the global Kainos PAT never reaches Copilot model calls.

Set the secret from the host opencode login:

```sh
sbx secret set opencode-copilot --command 'jq -r ".[\"github-copilot\"].refresh" "${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json"'
```

The kit needs a binding in sbx's credentials file. sbx reads
`$XDG_CONFIG_HOME/sbx/credentials.yaml`, which defaults to
`~/.config/sbx/credentials.yaml`:

```yaml
bindings:
  opencode-copilot:
    apiKey:
      domains:
        - api.githubcopilot.com
```

The binding contains no secret. sbx reads it on every request. An empty binding
makes opencode fail with an authorization error because the placeholder goes
upstream unchanged.

### What the VM sees

The real token never enters the sandbox. The proxy terminates TLS on the hosts
listed in the agent kit and replaces the placeholder header before forwarding.
Inside the VM:

- `GH_TOKEN` and `COPILOT_GITHUB_TOKEN` hold
  `gho_sbxproxymanaged000000000000000000000`.
- Provider keys hold `proxy-managed`.
- opencode's `~/.local/share/opencode/auth.json` holds the same
  `gho_sbxproxymanaged…` placeholder after the kit seed runs.

If no secret is available, the proxy tunnels without touching headers. GitHub
then rejects the literal placeholder, which is why a missing secret shows up as
`401 Bad credentials` instead of an empty token.

The proxy protects against token theft. It does not protect against misuse. A
sandbox can spend whatever the backing token allows, so the App permissions and
the WSL PAT scopes are the real limits.

## MCP

Sandboxed agents reach MCP servers through the host's sbx gateway. The gateway
runs in local mode, so OAuth tokens stay in the host secret store and the VM
receives only the gateway URL and a placeholder credential.

Run `sbx login` first. Every sbx command, `sbx mcp ls` included, returns 401
until you sign in to Docker.

On WSL, rebuild before registering `canvas-kit`. The wrapper is installed at
`/etc/profiles/per-user/dandyrow/bin/canvas-kit-mcp`.

Register context7 on every host:

```sh
sbx mcp add context7 --url https://mcp.context7.com/mcp/oauth \
  --scope profile --scope email --scope offline_access
```

The scopes matter. Without `offline_access`, sbx asks for `profile email` only
and gets no refresh token.

WSL also gets Atlassian and Canvas Kit:

```sh
sbx mcp add atlassian --url https://mcp.atlassian.com/v1/mcp/authv2
sbx mcp add canvas-kit --command /etc/profiles/per-user/dandyrow/bin/canvas-kit-mcp
```

Each `add` opens an OAuth consent URL. On WSL the Windows browser can reach the
localhost callback.

Use the wrapper path for Canvas Kit, not `npx`. The daemon starts local servers
with a PATH that has no `sh` or `node`, and `npx` needs both.

Check readiness:

```sh
sbx mcp ls
```

Every server should show `✓ ready`. If a consent fails, run `sbx mcp auth <name>`
and retry.

### Static mode

The launcher creates each sandbox with `--static-mcp` followed by every server
registered on the host. It reads that list from `sbx mcp ls --json`, so no host
hard-codes server names.

Static mode preloads every server at create. Tools are available from the first
turn and the agent has no `mcp-find` or `mcp-add` to attach anything else. The
cost is context: the WSL set is 59 tools, roughly 45 of them Atlassian's. The set
is fixed at create and cannot change on reattach. To add a server to a running
sandbox:

```sh
sbx mcp load <name> --sandbox <sbx>
```

### Client configuration

opencode is a built-in sbx integration. At create, sbx writes
`~/.config/opencode/opencode.json` with one remote server named `mcp-gateway`.

Copilot is not an integration, so it needs the `copilot-mcp` mixin kit. Nix
builds `nix/sbx-kits/copilot-mcp` into `/etc/sbx-kits/copilot-mcp.zip`, and the
kit installs `~/.copilot/mcp-config.json`:

```json
{
  "mcpServers": {
    "mcp-gateway": {
      "type": "http",
      "url": "http://mcp-gateway.docker.internal/mcp",
      "headers": {
        "Authorization": "Bearer proxy-managed"
      },
      "tools": ["*"]
    }
  }
}
```

Pass the kit on create. A file works however copilot starts inside the sandbox,
including through `sbx exec`.

The gateway also exposes `mcp-exec`, `code-mode`, and one `<server>-revoke-auth`
tool per OAuth server, even in static mode. An agent can revoke the host's
token. `sbx mcp auth <name>` restores it.

Figma is dropped. Its dynamic client registration endpoint returns 403, and sbx
is not in Figma's MCP catalog.

### MCP host state

`sbx mcp add` is a host action, not Nix. Registrations live in
`~/.local/state/sandboxes/sandboxes/sandboxd/mcp/servers/<name>.json`. Register
again on a fresh host, and re-register Canvas Kit only if the wrapper's path
changes.

## Network policy and SSH agent

Network policy and SSH-agent forwarding are set per host with sbx, not in this
repo. Run both steps once on each host, from the session that will run agents and
before creating a sandbox.

### Network policy

Every host, including DansSpectre and New-H0Ryzen:

```bash
sbx policy init allow-all
```

WSL is already initialised as Balanced. Reset it first:

```bash
sbx policy reset
sbx policy init allow-all
```

allow-all is one `**` allow rule. Do not add deny rules. An agent needs GitHub
reachable, and that is enough to move any file it can read, so a deny list does
not stop exfiltration. Kits cannot carry a global list either. v2 kits parse CIDR
denies but do not enforce them, and no setting applies a kit to every sandbox.

#### Accepted risk

allow-all lets a sandbox reach the LAN and the host's localhost through
`host.docker.internal`. That matters if a local service hands out a token over
TCP without auth. We have not found one.

### SSH agent forwarding

sbx enables forwarding by default. Turn it off on every host:

```bash
sbx settings set ssh.agentForwardingEnabled false && sbx daemon restart
```

Agents push over HTTPS through the proxy-injected PAT. `git` and `gh`
authenticate on the host side, and the VM only sees a placeholder token. The VM
has no SSH keys, so leaving `github.com:22` and `ssh.github.com:443` reachable
under allow-all gives it nothing to authenticate with.

### Observability

`sbx policy log` shows allowed and blocked hosts by sandbox, with the matching
rule and request count. `sbx policy log --json` gives the same data for scripts.

sbx also writes per-request audit JSONL under
`~/.local/state/sandboxes/sandboxes/auditkit/` and never deletes it. Policy
changes apply to running sandboxes immediately. Kit rules apply only when a
sandbox is created.

## Push gate

The `agent-gate` kit gives every sandbox a pre-push hook that refuses protected
refs, scans the commits being pushed for secrets, then runs the repo's own
`.agents/gate`. It is feedback for the agent, not enforcement. The `main`
ruleset and CI are the enforcement.

### What the hook does

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

It unsets `BETTERLEAKS_CONFIG` and the related `GITLEAKS_*` variables, then
passes a bundled config that enables the built-in rules, so neither the
environment nor a repository config can swap in a weaker ruleset.

The gate blocks a normal `git push`. It cannot stop `git push --no-verify`, an
agent that edits the hook after `sudo`, or a local `core.hooksPath` override.
Assume a mistaken agent, not a hostile one. CI runs `betterleaks` with its
default ruleset on every change, and the `main` ruleset requires `ci-ok`.

### Validate the kit

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

### CI secret scan

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

Update an existing `main` ruleset. This replaces the rules, removes every bypass
actor, and leaves out `required_signatures`:

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

Both must report `"enabled"`. Private repos on GitHub Free cannot use rulesets or
push protection; there the in-VM gate is the only check.

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

## End-to-end verification

CI builds the Nix checks but cannot run sbx. After switching a host, run the
checks below in order.

### Host state

```sh
sbx diagnose
sbx settings get ssh.agentForwardingEnabled
sbx policy log
sbx secret ls
```

`sbx settings get` must print `false`. `sbx policy log` shows traffic after a
sandbox has made requests; it can be empty on a fresh host.

On the personal hosts, `sbx secret ls` includes global `github` and no `copilot`.
On WSL it includes global `github` and `copilot`, plus `opencode-copilot` when
that kit is in use.

Check the mint without printing the token:

```sh
sbx-github-mint | cut -c1-4
```

The prefix is `ghs_`.

### Sandbox creation and clone mode

```sh
agent-sbx opencode
sbx ls
```

The sandbox name is `opencode-<repo basename>`. Inside it, the repository is a
clone, not a bind mount of the host checkout, and a host git hook cannot run.

Check the gate and the placeholder token:

```sh
sbx exec <sandbox> git config --system --get core.hooksPath
sbx exec <sandbox> printenv GH_TOKEN
```

The hook path is `/usr/local/lib/agent-gate/hooks`. The token is
`gho_sbxproxymanaged000000000000000000000`.

Check GitHub access and the commit identity:

```sh
sbx exec <sandbox> gh api installation/repositories
sbx exec <sandbox> git ls-remote https://github.com/<owner>/<repo>.git HEAD
sbx exec <sandbox> git log -1 --format='%an <%ae>'
```

`gh api user` fails for an App installation token with `Resource not accessible
by integration`. That is expected. Use an endpoint the installation can read.

### MCP

```sh
sbx mcp ls
sbx exec <sandbox> opencode models github-copilot
sbx exec <sandbox> jq . /home/agent/.local/share/opencode/auth.json
```

Every registered server shows `✓ ready`. `api.githubcopilot.com` shows as
`forward` in `sbx policy log`. The auth file holds the proxy placeholder, not a
real OAuth token.

For copilot, check the generated client file:

```sh
sbx exec <sandbox> cat /home/agent/.copilot/mcp-config.json
```

### Push gate

Inside the sandbox, attempt a protected push and a feature push:

```sh
sbx exec <sandbox> git push origin main
sbx exec <sandbox> git push origin HEAD:refs/heads/test-agent
```

The first is refused by the hook. The second passes the gate only when the
commits contain no secret and `.agents/gate` succeeds. The hook is installed
system-wide in the sandbox, so it applies to every repository in the VM.

### CI

Open a pull request and confirm `ci-ok` includes the `secret-scan` job. Push a
planted fake credential on a throwaway branch to confirm the scan fails, then
delete the branch. The scan uses generated test tokens in `nix/tests/sbx-gate.nix`;
do not commit a real one.
