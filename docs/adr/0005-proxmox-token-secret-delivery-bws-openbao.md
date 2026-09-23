# Proxmox token lives in BWS at bootstrap, OpenBao in steady state

The OpenTofu provider token has two homes, one per phase of the deployment's
life. Until the environment exists, Bitwarden Secrets Manager (BWS) holds it,
along with the OpenBao root token and unseal keys, because BWS is reachable
from a brand-new machine. Once the environment is live, OpenBao serves the
token and BWS keeps only the cold-start recovery copy.

The two stores answer different needs. Cold start works before the environment
exists, so its vault cannot live inside the environment; BWS does. Working
secrets should not sit on a third party for the lifetime of the deployment, so
once OpenBao is up the token moves there. The first applies read the token from
BWS through `bws`; the flip to OpenBao comes after, as
[#211](https://github.com/dandyrow/dotfiles/issues/211) does.

The bootstrap playbook stores the token it mints with the same env-var pattern
it authenticates with. `PROXMOX_HOST`, `PROXMOX_USER`, and `PROXMOX_PASSWORD`
enter via `lookup('ansible.builtin.env', ...)`, and the BWS access token plus
project identifiers ride the same way. No value is hardcoded, secret values are
masked from playbook output including `-vvv`, and nothing secret lands in the
repo.

## Considered Options

**One store for both phases.** Keeping every secret in BWS after bootstrap was
rejected. Steady state would live on a third party, and the material that
unseals the environment would sit beside the secrets it protects, so one
compromise hands over the stack.

**OpenBao from the first run.** Starting on OpenBao before anything exists was
rejected on its own terms: OpenBao needs its root token and unseal keys to
serve, and at cold start those have to live in BWS anyway. A single OpenBao
store still implies a bootstrap store; it just leaves it unstated.

**A gitignored secrets file on the controller.** The brief
`secrets/proxmox/provider-token` persist from #196 was reverted, see the #192
thread. It tied the token to one controller's filesystem and did not survive a
reinstall or a new machine, which is exactly when the bootstrap material is
needed.

## Not decided here

OpenBao's hosting model (docker, VM, podman, LXC, or k8s) is intentionally
open. It belongs to
[#209](https://github.com/dandyrow/dotfiles/issues/209), which decides and
records it as part of standing up the controller host. The two-store split does
not depend on how OpenBao runs.