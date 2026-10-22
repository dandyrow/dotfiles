# WSL development setup

Nix and Home Manager configure Linux. Windows VS Code, private checkouts and
credentials need separate setup.

## Restore a machine

1. **Build NixOS-WSL.** Follow the root README. Use a recorded dotfiles commit
   and its `flake.lock` for repeatable builds. Before evaluating WSL with
   `--impure`, place the corporate CA at `/etc/nixos/corp.pem` on the build
   machine. For a tarball build, include it in the private `--extra-files`
   directory too. Never commit certificates or credentials.

2. **Restore private tools.** Restore Workday-Extend-Tools at
   `~/Projects/work/EDM-AI/Workday-Extend-Tools`. The reviewed revision was
   `1608bbd835ff23cac72a56433136edacebc9c451`; record later revisions in your
   private backup. Run `npm ci` in `vscode-extension` and follow that
   repository's build instructions if shared assets are missing. Override
   `dandyrow.wdxCheckout` in Home Manager if you use another path.

   Restore `~/Projects/work/EDM-AI/wd-product-ai` separately if you use its
   private Copilot skills.

3. **Set up VS Code on Windows.** Install
   [VS Code](https://code.visualstudio.com/download) and Microsoft's WSL
   extension (`ms-vscode-remote.remote-wsl`). Sign in to GitHub and enable
   Copilot.

   In the Windows editor, open **Preferences: Open User Settings (JSON)** and
   merge [`vscode/windows-settings.json`](../vscode/windows-settings.json) into
   your settings. Replace `__WSL_HOME__` with your WSL home, usually
   `/home/dandyrow`. Keep existing sandbox grants. These settings must be in
   Windows User settings; WSL Remote settings did not affect the agent sandbox.
   The template disables automatic updates, so remove those entries if you
   prefer VS Code to update itself.

   Connect with **WSL: Connect to WSL using Distro**, choose NixOS, and open a
   workspace from the Linux filesystem. Allow HTTPS access to VS Code, the
   Marketplace and MCP endpoints. Corporate Windows certificate trust is
   separate from the WSL CA.

4. **Sign in and authorize servers.** In WSL, run `copilot login` and
   `gh auth login`. Sign in to GitHub/Copilot in VS Code too, then authorize
   Atlassian, Context7 and GitHub in each client as prompted. Each client keeps
   its own OAuth state.

   Provide required `WDX_DEV_*` or `WDX_TENANT_*` credentials through your
   approved secret manager. A VS Code-launched WSL server does not inherit
   variables from an unrelated terminal.

## Where configuration lives

- Copilot CLI reads `~/.config/copilot`, symlinked to
  `copilot/.config/copilot` in the dotfiles. Runtime state is ignored by Git;
  back up sessions and sign-in state separately. Edit `mcp-config.json` to
  change server entries.
- VS Code's MCP config and `server-env-setup` are symlinked from
  `vscode/.vscode-server/`. The WSL extension uses `~/.vscode-server` for its
  binaries and setup script.
- Canvas Kit runs with `npx -y @workday/canvas-kit-mcp@16.2.3`. Its first start
  needs network access and writes to `~/.cache/npm`, which the Windows sandbox
  settings allow.
- Copilot CLI provides GitHub MCP after login. VS Code has a separate HTTP
  GitHub MCP entry. Do not add a second GitHub entry to Copilot CLI.
- WDX uses the private checkout and retains its own permission gates. It is not
  read-only, and credentials may enable deploy operations.

## Verify

Before switching:

```bash
nix flake check
nix eval --impure .#nixosConfigurations.WSL.config.system.build.toplevel.drvPath
```

After an approved rebuild, run **WSL: Kill VS Code Server**, reconnect to NixOS,
and open a fresh WSL terminal:

```bash
printf '%s\n' "$COPILOT_HOME"
copilot --version
copilot mcp list
wdx --help
```

Copilot should use `~/.config/copilot` and list GitHub, Atlassian, Context7,
Canvas Kit and WDX. In VS Code, run **MCP: Open Remote User Configuration** and
**MCP: List Servers**, authorize and start the servers, then try a documentation
lookup and a read-only WDX reference tool. Check the actual clients; Nix
evaluation cannot verify sign-in or authenticated requests.
