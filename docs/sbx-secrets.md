# sbx secrets and agent identity

Sandboxed agents never hold a real GitHub token. The host stores one credential
per host, sbx swaps a placeholder for the real value inside its proxy, and the
VM only ever sees the placeholder. Git commits use a fixed bot identity so a
human can review what the agent did.

## Where credentials live

| Host | GitHub App ID and private key | sbx secret store |
| --- | --- | --- |
| DansSpectre, New-H0Ryzen | GNOME Keyring, service `sbx-github-app`, attributes `host=<host>` and `kind=app-id` or `kind=private-key` | GNOME Keyring, `login` collection, `service:group=com.docker.sandboxes` |
| WSL | `$XDG_CONFIG_HOME/sbx/github-app-id` and `$XDG_CONFIG_HOME/sbx/github-app.pem`, mode 0600 | age-encrypted files under `$XDG_CONFIG_HOME/com.docker.sandboxes/` |

`XDG_CONFIG_HOME` defaults to `$HOME/.config`. The file store on WSL has a
constant scrypt password that ships in the sbx binary, so file permissions do
the real work there. This matches the risk already accepted for the host `gh`
token in `~/.config/gh/hosts.yml`.

sbx picks its backend itself. It tries Secret Service over D-Bus first and
falls back to the file store when no keyring owns `org.freedesktop.secrets`.
Keep the CLI and the daemon in the same session and the same `XDG_CONFIG_HOME`.

## Git identity

The launcher passes the identity as four `-e` flags on `sbx create`:

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

The values come from the Home Manager options `dandyrow.sbxIdentity.gitIdentity.name`
and `dandyrow.sbxIdentity.gitIdentity.email`. On WSL every sandbox commits as
Copilot, including Kainos sandboxes. On the personal hosts the identity matches
the OpenCode Agent App owned by `anomalyco`.

## GitHub identity per host

Each host has its own GitHub App, named `dandyrow-agent-<host>`. The App owns
the App installation token. The install covers all repositories owned by
`dandyrow`. App permissions are:

- Read and write: Contents, Pull requests, Issues, Actions, Commit statuses.
- Read: Metadata.
- No Workflows and no Administration.

A token minted by the App lasts one hour. `sbx secret set --command` stores the
command text and reruns it once the cached value is 55 minutes old, so the proxy
never sends a token older than that.

The App shows up as `<app>[bot]` on GitHub. The App's own noreply address is not
used for commits because the git identity above is fixed per host.

## Per-host secrets

### DansSpectre and New-H0Ryzen

The global `github` secret is the App mint. There is no `copilot` secret because
neither host has a Copilot seat.

```sh
sbx secret set github --command 'sbx-github-mint'
```

Once this works, delete the old `sbx-DansSpectre` and `sbx-New-H0Ryzen` PATs in
GitHub.

### WSL

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

The override works before or after `sbx create`. It takes effect on the next
request without a restart, and `sbx rm` deletes it. The global `github` secret
must still exist at create time because it sets the `GH_TOKEN` placeholder.

Personal and Kainos routing is decided by the launcher from the repository
origin. A `dandyrow` origin gets the App override. Any other origin is Kainos
and keeps the global PAT.

## Register a host App

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

## Mint an installation token

```sh
sbx-github-mint
```

The command reads the host App ID and private key, builds an RS256 JWT with
`iat` set to 60 seconds ago and `exp` set to 10 minutes from now, lists
`/app/installations`, and exchanges the JWT for an installation token. It
prints only the token to stdout so `sbx secret set --command` can consume it.
Missing credentials, a missing installation, or a failed GitHub request writes
an actionable error to stderr and exits nonzero.

Run it by hand to check registration:

```sh
sbx-github-mint | cut -c1-4
```

The prefix is `ghs_`. Do not print the whole token.

## opencode Copilot on WSL

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

## What the VM sees

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

## Verification

Check that the host has the expected secrets:

```sh
sbx secret ls
```

On WSL the list includes global `github` and `copilot`, plus
`opencode-copilot` when that kit is in use. On the personal hosts the list
includes global `github` and no `copilot`.

Check the mint and the VM without printing the token:

```sh
sbx-github-mint | cut -c1-4
sbx exec <sandbox> -- printenv GH_TOKEN
sbx exec <sandbox> -- gh api installation/repositories
sbx exec <sandbox> -- git ls-remote https://github.com/<owner>/<repo>.git HEAD
sbx policy log
```

`gh api user` fails for an App installation token with `Resource not accessible
by integration`. That is expected. Use an endpoint the installation can read.

For opencode, check the provider and the proxy path:

```sh
sbx exec <sandbox> -- opencode models github-copilot
sbx exec <sandbox> -- jq . /home/agent/.local/share/opencode/auth.json
```

`api.githubcopilot.com` should show as `forward` in `sbx policy log`.

## Launcher inputs

The launcher reads these Home Manager options from
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

Any new config or data path goes under XDG. The exceptions are sbx's own fixed
paths under `$XDG_CONFIG_HOME/sbx/` and `$XDG_CONFIG_HOME/com.docker.sandboxes/`.
