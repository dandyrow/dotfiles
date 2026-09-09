# Ansible

Ansible content for this repo. `proxmox.yml` bootstraps the least-privilege
Proxmox user OpenTofu uses to deploy VMs.

## proxmox.yml bootstrap

Recreates the `terraform@pve` user, `Terraform` role, ACL, and `provider` API
token that OpenTofu uses to deploy VMs on the Proxmox host. Run it from a
clean host after a total loss; it authenticates to the Proxmox API as
`root@pam` for the one-time bootstrap. `root@pam` is recreated at every
install, so it survives a loss where a token-based credential would not.

The `Terraform` role only covers what the New-H0Ryzen deploy needs: VM
create/manage, cloud-init, local LVM storage, and GPU/USB passthrough via
hardware mappings. `User.Modify` is off-limits so the token can't grant itself
more rights.

The playbook has no SSH dependency: the `community.proxmox` modules drive the
API from the controller, the same transport the steady-state OpenTofu/bpg
provider will use.

### Run

The controller needs `ansible-core`, the collection's Python runtime deps on
the interpreter that executes the module (`proxmoxer >= 2.3`, `requests`), and
the collection itself. The `ansible` metapackage alone does not provide those
Python libs. NixOS env that carries all three — `community.proxmox` ships
bundled with the env's Ansible (`>= 2.0.0`, so nothing to install):

```
nix shell --impure --expr 'let pkgs = import <nixpkgs> {}; in pkgs.python3.withPackages (ps: [ ps.ansible-core ps.proxmoxer ps.requests ])'
```

Non-NixOS controllers: install `ansible-core`, `proxmoxer` and `requests`,
then `ansible-galaxy collection install -r requirements.yml`.

Auth comes from environment variables resolved via
`lookup('ansible.builtin.env', ...)`; the collection marks `api_password`
`no_log`, so the root password is masked in all output including `-vvv`.

```
cd ansible
export PROXMOX_HOST=https://pve.example.net:8006
export PROXMOX_USER=root@pam
read -rs PROXMOX_PASSWORD   # silent read keeps the root password out of shell history
export PROXMOX_PASSWORD
export PROXMOX_VALIDATE_CERTS=false   # only needed if the node cert isn't trusted yet
ansible-playbook proxmox.yml -e ansible_python_interpreter=$(which python3)
```

The first run writes the token secret to `secrets/proxmox/provider-token`
(gitignored, mode 0600) at the repo root — the copy OpenTofu reads at apply
time. Controller-only: install flows stage only the `etc/` subtree, so the
token never reaches a VM. Keep a separate copy in your password manager as a
personal record. Later runs are no-ops.

### Rotating a lost secret

If the secret is lost and the token still exists, force a fresh one with the
same env vars as above plus the regenerate flag. The playbook drops the
user's tokens (this user only ever has `provider`), then mints a new one and
rewrites the token file.

```
cd ansible
ansible-playbook proxmox.yml -e proxmox_bootstrap_regenerate_token=true -e ansible_python_interpreter=$(which python3)
```

### What gets created

| Item | Value |
| --- | --- |
| User | `terraform@pve` |
| Role | `Terraform` |
| ACL | `/` bound to `terraform@pve` with `Terraform` |
| Token | `provider`, `privsep: false`, inheriting the scoped role |

Verify with `pveum user permissions terraform@pve` on the host.
