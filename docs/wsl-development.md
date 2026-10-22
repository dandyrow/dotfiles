# WSL development setup

Nix restores everything on the Linux side. These are the manual steps it can't do.

## Restore steps

1. Clone Workday-Extend-Tools to `~/Projects/work/EDM-AI/Workday-Extend-Tools`
   and run `npm ci` in its `vscode-extension` directory. The `wdx` wrapper
   expects it there. Set `dandyrow.wdxCheckout` in Home Manager to use another path.
2. On Windows, install [VS Code](https://code.visualstudio.com/download) and the
   WSL extension (`ms-vscode-remote.remote-wsl`), then sign in to GitHub.
3. In Windows VS Code, run **Preferences: Open User Settings (JSON)** and merge in
   [`vscode/windows-settings.json`](../vscode/windows-settings.json). Replace
   `__WSL_HOME__` with your WSL home, e.g. `/home/dandyrow`. It has to be the
   Windows User settings; the agent sandbox ignores WSL Remote settings.
4. Run **WSL: Connect to WSL using Distro** and pick NixOS.
5. In a WSL terminal, run `copilot login` and `gh auth login`.
6. Authorize Atlassian, Context7 and GitHub when Copilot CLI and VS Code prompt.
   Each keeps its own sign-in.
7. Load the `WDX_DEV_*` or `WDX_TENANT_*` credentials from your secret manager.

After any rebuild that touches VS Code config, run **WSL: Kill VS Code Server**
and reconnect. The server reads `server-env-setup` (`PATH`, `COPILOT_HOME`) only
when it starts, so a reload alone keeps the old environment.

## Where config lives

| What | File |
| --- | --- |
| Copilot CLI MCP servers | [`copilot/.config/copilot/mcp-config.json`](../copilot/.config/copilot/mcp-config.json) |
| Copilot CLI settings and URL permissions | [`copilot/.config/copilot/settings.json`](../copilot/.config/copilot/settings.json) |
| VS Code MCP servers | [`vscode/.vscode-server/data/User/mcp.json`](../vscode/.vscode-server/data/User/mcp.json) |
| VS Code server environment | [`vscode/.vscode-server/server-env-setup`](../vscode/.vscode-server/server-env-setup) |

Copilot CLI already has GitHub MCP after `copilot login`, so don't add it to
`mcp-config.json`.

Copilot CLI saves URL permissions as `allowedUrls` and `deniedUrls` in
`settings.json`. Tool permissions are either `--allow-tool`/`--deny-tool` flags
or approvals that last one session. VS Code's own chat tool approvals are set in
VS Code settings and don't touch these files.
