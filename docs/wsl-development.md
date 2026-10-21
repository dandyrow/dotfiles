# WSL development environment

NixOS installs the Linux packages. Home Manager symlinks the MCP configuration
from the dotfiles.
Windows runs a separate, pinned VS Code installation. Rebuilding NixOS does not
install software on Windows or restore private repositories and credentials.

## What is reproducible

| Component | Source of truth |
| --- | --- |
| NixOS, Node, Copilot CLI, GitHub CLI | `flake.lock` and the Nix modules |
| Canvas Kit MCP, including transitive dependencies | `nix/pkgs/canvas-kit-mcp/` and its Nix dependency hash |
| Copilot CLI MCP definitions | Symlinked `copilot/.config/copilot/mcp-config.json` |
| Work Copilot MCP definitions | Symlinked `copilot/.config/copilot-work/mcp-config.json` |
| VS Code MCP definitions and server environment | Symlinked files under `vscode/.vscode-server/` |
| Windows VS Code and WSL extension | `vscode/windows-lock.json`, including archive SHA256 hashes |
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

### 3. Bootstrap the Windows editor

From Windows PowerShell, run the script from the same dotfiles revision:

```powershell
& '\\wsl.localhost\NixOS\home\dandyrow\.dotfiles\scripts\bootstrap-vscode.ps1' -Launch
```

Use `-LinuxUser` and `-Distro` if those names differ. The bootstrap requires
Windows x64, PowerShell 5.1 or newer, and HTTPS access to the VS Code update
service and Visual Studio Marketplace. Corporate Windows certificate trust is
a Windows prerequisite, separate from the WSL CA.

The script verifies download hashes, installs the locked WSL extension, disables
automatic editor/extension updates, and writes settings in its own user-data
directory. Copilot support is built into the pinned VS Code release.
It does not install a Linux desktop editor, require administrator privileges,
or overwrite your existing VS Code installation.

Use the generated launcher for subsequent sessions:

```powershell
& "$env:LOCALAPPDATA\Programs\dotfiles-vscode\code-wsl.cmd"
```

Its settings are at `%APPDATA%\dotfiles-vscode\User\settings.json` and are
replaced on bootstrap reruns. Other editor profiles are untouched. Manual
extension installs can still change this profile; avoid them for exact
restoration. Update the lock and verified hashes deliberately to receive
security fixes.

Sandbox settings must be in the **Windows User settings of the launching
editor** for this agent-host setup. Putting the same settings only in WSL
Remote Settings did not affect the effective policy during testing.
The bootstrap grants read access to the Nix store/profile trees and daemon
socket, plus write access to the user's Nix cache. It leaves sandboxing on.
Daemon access permits Nix to fetch and build packages.

Run `/sandbox policy` in a new agent session to confirm the grants. A successful
policy report alone does not prove that commands can start.

### 4. Sign in and authorize MCP

- Run `copilot login` and `gh auth login` inside WSL.
- Sign in to GitHub/Copilot in the managed Windows VS Code window.
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
to the common or work-specific Copilot configuration in the dotfiles checkout.
Copilot runtime files remain there, as they do now. `.gitignore` excludes
runtime state and keeps the managed configuration. Back up sessions and sign-in
state separately when moving machines. Edit the selected `mcp-config.json`
instead of using `/mcp add`.

VS Code remote MCP configuration is symlinked from
`vscode/.vscode-server/data/User/mcp.json`. Its environment setup script is also
symlinked from the dotfiles and adds Nix profile paths before the remote agent
starts. These VS Code paths are upstream defaults, not XDG-configurable.

## Verification

Before switching:

```bash
nix flake check
nix eval .#nixosConfigurations.WSL.config.system.build.toplevel.drvPath --impure
```

After an approved rebuild, stop the existing WSL VS Code server through
**WSL: Kill VS Code Server**, reconnect with the managed Windows launcher, and
open a fresh WSL terminal:

```bash
printf '%s\n' "$COPILOT_HOME"
copilot --version
copilot mcp list
wdx --help
node scripts/tests/mcp-smoke.mjs "$(command -v wdx)" mcp
```

Expect Copilot's state home at `~/.config/copilot`, the built-in GitHub server,
Atlassian, Context7, Canvas Kit and WDX. In VS Code, use
**MCP: Open Remote User Configuration** and **MCP: List Servers**. Authorize and
start each server, then exercise a documentation lookup and a read-only WDX
reference tool. Verify remote execution in a WSL workspace, not a Windows folder.

Authenticated HTTP calls, Windows installation, OAuth callbacks and the
post-switch editor environment must be checked on the actual clients. Nix
evaluation and the local stdio smoke tests cannot prove those steps work.
