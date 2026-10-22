# Sandbox network policy and SSH agent

Network policy and SSH-agent forwarding are set per host with sbx, not in this repo. Run both steps once on each host, from the session that will run agents and before creating a sandbox.

## Network policy

Every host, including DansSpectre and New-H0Ryzen:

```bash
sbx policy init allow-all
```

WSL is already initialised as Balanced. Reset it first:

```bash
sbx policy reset
sbx policy init allow-all
```

`sbx policy reset` deletes the local policy store and stops the daemon. Running sandboxes stop, and it asks for confirmation unless you pass `--force`.

allow-all is one `**` allow rule. Do not add deny rules. An agent needs GitHub reachable, and that is enough to move any file it can read, so a deny list does not stop exfiltration. Kits cannot carry a global list either. v2 kits parse CIDR denies but do not enforce them, and no setting applies a kit to every sandbox.

### Accepted risk

allow-all lets a sandbox reach the LAN and the host's localhost through `host.docker.internal`. That matters if a local service hands out a token over TCP without auth. We have not found one.

## SSH agent forwarding

sbx enables forwarding by default. Turn it off on every host:

```bash
sbx settings set ssh.agentForwardingEnabled false && sbx daemon restart
```

Agents push over HTTPS through the proxy-injected PAT. `git` and `gh` authenticate on the host side, and the VM only sees a placeholder token. The VM has no SSH keys, so leaving `github.com:22` and `ssh.github.com:443` reachable under allow-all gives it nothing to authenticate with.

## Observability

`sbx policy log` shows allowed and blocked hosts by sandbox, with the matching rule and request count. `sbx policy log --json` gives the same data for scripts.

sbx also writes per-request audit JSONL under `~/.local/state/sandboxes/sandboxes/auditkit/` and never deletes it. Policy changes apply to running sandboxes immediately. Kit rules apply only when a sandbox is created.

## Verification

```bash
sbx settings get ssh.agentForwardingEnabled
sbx policy log
sbx diagnose
```

`sbx settings get` must print `false`. `sbx policy log` shows traffic after a sandbox has made requests. `sbx diagnose` checks the daemon, KVM, and storage.
