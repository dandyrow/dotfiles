# WSL development environment

NixOS installs the Linux packages. Home Manager symlinks the MCP configuration
from the dotfiles.
Windows runs a separately installed VS Code editor. Rebuilding NixOS does not
install software on Windows or restore private repositories and credentials.

## What is reproducible

| Component | Source of truth |
| --- | --- |
| NixOS, Node, Copilot CLI, GitHub CLI | `flake.lock` and the Nix modules |
| Canvas Kit MCP version | `npx` version pin in both MCP configs, cached by npm under `~/.cache/npm` on first start |
| Copilot CLI MCP definitions | Symlinked `copilot/.config/copilot/mcp-config.json` |
| VS Code MCP definitions and server environment | Symlinked files under `vscode/` |
| Windows VS Code and WSL extension | Manually installed on Windows, not pinned by this repository |
| Windows editor settings and Nix sandbox access | `vscode/windows-settings.json` |
| WDX runtime | Nix Node wrapper around your separately restored private checkout |

The HTTP services are hosted by Atlassian, GitHub and Context7. Their URLs and
client configuration are declarative, but their server implementations cannot
be pinned by this repository. OAuth grants, subscriptions, enterprise policies
and service availability remain external requirements.

WDX deliberately uses a mutable private checkout rather than putting company
source in this repository or a public binary cache. Changing that checkout
changes WDX without a Nix rebuild. Copilot's existing marketplace plugins and
the private `wd-product-ai` skill checkout are also not pinned by this setup.

## Restore a machine

### 1. Install NixOS-WSL

Follow the WSL installation steps in the root README. Build from a recorded
dotfiles commit and its committed `flake.lock`; do not update the lock during
restoration. Keep the checkout at that revision for an exact restoration,
because other dotfiles still use out-of-store links.

The corporate CA must be at `/etc/nixos/corp.pem` on the **build machine**
before evaluating WSL with `--impure`. If building a tarball elsewhere, also
include `etc/nixos/corp.pem` in the private `--extra-files` directory so future
rebuilds in the imported distro can find it. Never commit the certificate,
password hashes or credentials. Node processes use the NixOS CA bundle.

### 2. Restore WDX separately

Restore the private Workday-Extend-Tools repository at:

```text
~/Projects/work/EDM-AI/Workday-Extend-Tools
```

For repeatable restoration, record the revision in your private backup. The
revision inspected during this review was
`1608bbd835ff23cac72a56433136edacebc9c451`.
Use its committed npm lockfile:

```bash
cd ~/Projects/work/EDM-AI/Workday-Extend-Tools
git checkout <your-recorded-revision>
cd vscode-extension
npm ci
```

The repository's normal preparation step must also have generated its shared
assets. Consult its own build instructions if they are missing. No global npm
installation is needed. Override `dandyrow.wdxCheckout` in Home Manager if you
use another location. The wrapper reports a missing checkout explicitly.

Restore `~/Projects/work/EDM-AI/wd-product-ai` separately if you want the private
skills referenced by the existing Copilot settings.

### 3. Set up VS Code on Windows

1. Install [VS Code for Windows](https://code.visualstudio.com/download).
   No Linux desktop editor is needed.
2. In the Windows editor, install Microsoft's **WSL** extension,
   `ms-vscode-remote.remote-wsl`.
3. Sign in to GitHub and enable GitHub Copilot chat. If your VS Code release
   offers Copilot through an extension, install the GitHub Copilot extension
   recommended by the editor. Your account must have Copilot access.
4. Open **Preferences: Open User Settings (JSON)** in the Windows editor.
   Merge the settings from [`vscode/windows-settings.json`](../vscode/windows-settings.json)
   into your existing settings. Replace every `__WSL_HOME__` with your Linux
   home, normally `/home/dandyrow`. Preserve any existing sandbox path grants.
   The template disables automatic editor and extension updates; keep those
   settings only if you intend to manage updates manually.
5. Run **WSL: Connect to WSL using Distro**, select your NixOS distro, then
   open your workspace inside its Linux filesystem.

The default Windows User settings file is
`%APPDATA%\Code\User\settings.json`. Use the command above for the active
profile rather than assuming that path applies to every profile.
Windows VS Code and extension versions are managed manually, outside Nix.
Record their versions in your machine backup if you need to reinstall the same
releases, and apply security updates deliberately.

HTTPS access to VS Code services, the Visual Studio Marketplace and the MCP
endpoints is required. Corporate Windows certificate trust is a Windows
prerequisite, separate from the WSL CA.

Sandbox settings must be in the **Windows User settings of the launching
editor** for this agent-host setup. Putting the same settings only in WSL
Remote Settings did not affect the effective policy during testing.
The settings template grants read access to the Nix store/profile trees and
daemon socket, plus write access to the user's Nix and npm caches. npm needs
its cache for Canvas Kit's pinned `npx` command. It leaves sandboxing on.
Daemon access permits Nix to fetch and build packages.

Run `/sandbox policy` in a new agent session to confirm the grants. A successful
policy report alone does not prove that commands can start.

### 4. Sign in and authorize MCP

- Run `copilot login` and `gh auth login` inside WSL.
- Sign in to GitHub/Copilot in the Windows VS Code window connected to WSL.
- Authorize Atlassian, Context7 if requested, and GitHub separately in each
  client. OAuth state is not copied into Nix or shared between clients.
- Supply any required `WDX_DEV_*` / `WDX_TENANT_*` credentials through your
  approved secret manager. Never put them in Nix, MCP JSON or source control.
  A Windows-launched WSL server does not inherit variables exported only in an
  unrelated terminal.

Copilot CLI already supplies `github-mcp-server` after login. Adding a second
GitHub entry would duplicate it. VS Code instead gets an explicit HTTP GitHub
entry in its remote user MCP configuration. The CLI's built-in GitHub server
has fewer default tools; use `gh` for the rest or explicitly enable additional
GitHub toolsets.

WDX uses `wdx mcp` without tenant-write override flags. Its own permission gates
still apply; this is not read-only mode, and personal-app deploys may be
available with credentials. The optional Workday editor extension is not
required for the headless MCP server.

## Configuration and runtime state

`COPILOT_HOME` stays `~/.config/copilot`. Home Manager symlinks that directory
to `copilot/.config/copilot` in the dotfiles checkout. Copilot runtime files
remain there, as they do now. `.gitignore` excludes runtime state and keeps the
managed configuration. Back up sessions and sign-in state separately when moving
machines. Edit `mcp-config.json` instead of using `/mcp add`.

The VS Code server keeps its data and extensions in
`~/.local/share/vscode-server`. `server-env-setup` sets `VSCODE_AGENT_FOLDER` to
that path and adds the Nix profile paths before the server starts. The WSL
extension hardcodes `~/.vscode-server` for the server binaries and for
`server-env-setup` itself, so that directory still exists but holds only
downloads you can delete and reinstall.

Home Manager symlinks the remote MCP configuration from
`vscode/.local/share/vscode-server/data/User/mcp.json` and `server-env-setup`
from `vscode/.vscode-server/server-env-setup`.

### Move existing VS Code server data

Machines that ran VS Code before this change have their remote settings,
extensions and chat history in `~/.vscode-server`. Move them once after the
rebuild. Run **WSL: Kill VS Code Server** in VS Code and close every VS Code
window, then run this from a WSL terminal that VS Code did not open:

```bash
mkdir -p ~/.local/share/vscode-server
cp -a --update=none ~/.vscode-server/data ~/.vscode-server/extensions ~/.local/share/vscode-server/
```

`--update=none` keeps the `mcp.json` link Home Manager already created. Once VS Code
reconnects with your settings and extensions, delete the old copies with
`rm -rf ~/.vscode-server/data ~/.vscode-server/extensions`.

## Verification

Before switching:

```bash
nix flake check
nix eval .#nixosConfigurations.WSL.config.system.build.toplevel.drvPath --impure
```

After an approved rebuild, move existing VS Code server data as described
above. Then reconnect to the NixOS distro in VS Code and open a fresh WSL
terminal:

```bash
printf '%s\n' "$COPILOT_HOME"
copilot --version
copilot mcp list
wdx --help
ls ~/.local/share/vscode-server
```

Expect Copilot's state home at `~/.config/copilot`, the built-in GitHub server,
Atlassian, Context7, Canvas Kit and WDX, and VS Code's `data` and `extensions`
directories under `~/.local/share/vscode-server`. In VS Code, use
**MCP: Open Remote User Configuration** and **MCP: List Servers**. Authorize and
start each server, then exercise a documentation lookup and a read-only WDX
reference tool. Verify remote execution in a WSL workspace, not a Windows folder.

Authenticated HTTP calls, Windows installation, OAuth callbacks and the
post-switch editor environment must be checked on the actual clients. Nix
evaluation cannot prove those steps work.
