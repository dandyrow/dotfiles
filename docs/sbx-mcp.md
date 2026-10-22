# MCP in sandboxes

Sandboxed agents reach MCP servers through the host's sbx gateway. The gateway
runs in local mode, so OAuth tokens stay in the host secret store and the VM
receives only the gateway URL and a placeholder credential.

## Prerequisites

Run `sbx login` on the host first. Every sbx command, `sbx mcp ls` included,
returns 401 until you sign in to Docker.

On WSL, rebuild before registering `canvas-kit`. The wrapper is installed at
`/etc/profiles/per-user/dandyrow/bin/canvas-kit-mcp`.

## Register servers

All hosts get context7:

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

## Static mode

The launcher (#306) creates each sandbox with `--static-mcp` followed by every
server registered on the host. It reads that list from `sbx mcp ls --json`, so
no host hard-codes server names.

Static mode preloads every server at create. Tools are available from the first
turn and the agent has no `mcp-find` or `mcp-add` to attach anything else. The
cost is context: the WSL set is 59 tools, roughly 45 of them Atlassian's. The
set is fixed at create and cannot change on reattach. Use
`sbx mcp load <name> --sandbox <sbx>` to add a server to a running sandbox.

## Client config

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

## Credentials

OAuth tokens live in the host sbx secret store under
`docker/sandbox/oauth/mcp/<name>`. That is the file store on WSL and GNOME
Keyring on the GDM hosts. No MCP credential enters the VM.

The VM gets `MCP_GATEWAY_URL=http://mcp-gateway.docker.internal/mcp` and sends
`Authorization: Bearer proxy-managed`. The host proxy swaps the placeholder for
the real token. The gateway hostname has no DNS inside the VM, so MCP clients
must send traffic through the sandbox `HTTP(S)_PROXY`. The host makes the remote
calls, so the sandbox network policy needs no MCP hosts.

The gateway also exposes `mcp-exec`, `code-mode`, and one `<server>-revoke-auth`
tool per OAuth server, even in static mode. An agent can revoke the host's
token. `sbx mcp auth <name>` restores it.

Figma is dropped. Its dynamic client registration endpoint returns 403, and sbx
is not in Figma's MCP catalog.

## Host state

`sbx mcp add` is a host action, not Nix. Registrations live in
`~/.local/state/sandboxes/sandboxes/sandboxd/mcp/servers/<name>.json`. Register
again on a fresh host, and re-register Canvas Kit only if the wrapper's path
changes.
