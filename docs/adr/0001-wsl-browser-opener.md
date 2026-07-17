# ADR-0001: Open browsers from WSL via `wsl-open`, not a Linux GUI browser

- **Status:** Accepted
- **Date:** 2026-07-17
- **Scope:** WSL host (`nix/hosts/WSL`), home module (`nix/home/default.nix`)

## Context

On the WSL host the standard opener path is dead on arrival: `xdg-open` is
not on `PATH` and `$BROWSER` is empty. Apps that opened the browser did so
only by hard-coding a Windows `.exe` (`explorer.exe`, `powershell.exe Start`)
through binfmt interop. Anything using the generic `xdg-open` / `$BROWSER`
path — including agent tooling that writes to `/tmp` and calls `xdg-open` —
failed silently.

The goal was a single, generic, reliable opener reachable through that
standard path. Two broad routes existed:

- **(a) Hand off to the Windows browser** via interop.
- **(b) Run a Linux GUI browser under WSLg** and register it as the
  `xdg-open` handler, mirroring the desktop `hasDesktop` Firefox wiring.

`wslu` (the usual source of `wslview`) has been removed from nixpkgs — the
project is archived — so that specific tool is not an option.

## Decision

Route to the **Windows default browser** via `pkgs.wsl-open`, gated on
`osConfig.wsl.enable` in the shared home module. Set `BROWSER=wsl-open` and
alias `xdg-open` → `wsl-open` so both integration paths resolve to the same
opener. `wsl-open` converts WSL paths and copies non-Windows-filesystem
files to Windows `%TEMP%` when needed, then opens via `powershell.exe Start`.

## Wayland / X11 considerations

Avoiding X11 was a hard constraint, and it drove the choice of route (a):

- Route (b) means running a Linux browser under **WSLg**, which provides a
  Wayland compositor *and* an XWayland (X11) server. Even a Wayland-native
  Firefox drags a GUI stack into the WSL closure, and many GUI helpers still
  fall back to XWayland — exactly the X11 surface we want to keep out.
- Route (a) runs **no Linux GUI at all** — the browser lives on the Windows
  side — so it introduces **zero Linux display-server dependency**, X11 or
  Wayland. This is the cleanest way to honour "avoid X11": there is simply no
  Linux display stack in play.
- This keeps WSL consistent with the repo's Wayland-leaning desktop posture
  (`wl-clipboard`, no X11 clipboard) by not smuggling X11 in as a side effect.
- **If** a future need requires an actual Linux GUI under WSL, prefer WSLg's
  Wayland path and run apps Wayland-native (e.g. `MOZ_ENABLE_WAYLAND=1`),
  explicitly avoiding XWayland — and revisit this ADR then.

## Consequences

- Reliable generic opening through the standard `xdg-open` / `$BROWSER` path.
- No Linux display stack (X11 *or* Wayland) added to the WSL closure.
- One seam, gated on `wsl.enable`, colocated with the desktop browser wiring.
- Tradeoff: opens the *Windows* browser rather than a Linux one — desired on
  WSL. Depends on `wsl-open` (a small, maintained shell script) plus
  `powershell.exe` interop.
- `xdg-open` is shadowed by a WSL-aware replacement rather than real
  `xdg-utils`. Correct on a headless WSL host with no mime database to defer
  to; note this if a real desktop mime system is ever wanted here.

## Alternatives considered

- **`wslu` / `wslview`** — removed from nixpkgs (project archived). Rejected.
- **Real `xdg-utils` + `xdg.mimeApps` handler** — needs `.desktop` files and a
  working mime database; fragile on a headless WSL host. Rejected.
- **Linux browser under WSLg** — risks pulling in X11 via XWayland, heavier
  closure, contrary to the avoid-X11 constraint. Rejected.
