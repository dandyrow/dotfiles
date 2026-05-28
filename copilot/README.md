# GitHub Copilot CLI

Stow package for GitHub Copilot CLI configuration.

## Layout

```
copilot/.config/copilot/mcp-config.json
```

Copilot CLI reads its config from `~/.copilot/` by default. This package
relies on `COPILOT_HOME="$XDG_CONFIG_HOME/copilot"` (set in
`zsh/.config/zsh/.zshrc`) to redirect Copilot to the XDG location, so a
plain `stow copilot` works.

## Bootstrap on a new machine

1. Install Copilot CLI: <https://docs.github.com/copilot/how-tos/set-up/install-copilot-cli>
2. Ensure `COPILOT_HOME` is exported (provided by the `zsh` package).
3. Stow this package: `stow copilot`
4. Start Copilot once and run `/login` to authenticate.
5. Install the Superpowers plugin (not file-managed — lives in Copilot's
   data dir):

   ```
   copilot plugin marketplace add obra/superpowers-marketplace
   copilot plugin install superpowers@superpowers-marketplace
   ```

6. The two remote MCP servers (Context7, Atlassian) use OAuth. On first
   use, Copilot CLI will trigger the browser-based auth flow for each.
   Tokens are cached by Copilot.

## MCP servers

| Name      | Transport | URL                                |
| --------- | --------- | ---------------------------------- |
| context7  | http      | <https://mcp.context7.com/mcp>     |
| atlassian | sse       | <https://mcp.atlassian.com/v1/sse> |

If Copilot CLI's native remote-OAuth flow fails for either server, the
fallback is to run them as local stdio via `npx mcp-remote@latest <url>`
— `mcp-remote` handles the OAuth dance and exposes the remote server
over stdio.
