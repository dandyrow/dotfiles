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
Python libs. The root flake's `ansible` devShell supplies all three plus `bws`
— `community.proxmox` ships bundled with the env's Ansible (`>= 2.0.0`, so
nothing to install):

```
nix develop ..#ansible
```

Non-NixOS controllers: install `ansible-core`, `proxmoxer` and `requests`,
`bws`, then `ansible-galaxy collection install -r requirements.yml`.

Auth comes from environment variables resolved via
`lookup('ansible.builtin.env', ...)`; the collection marks `api_password`
`no_log`, so the root password is masked in all output including `-vvv`. The
BWS bootstrap store is written the same way: the access token and project id
come from env vars in the same style, and the token write is masked via
`no_log`. The machine account backing `BWS_ACCESS_TOKEN` must have write
access to the project.

```
cd ansible
export PROXMOX_HOST=pve.example.net:8006
export PROXMOX_USER=root@pam
read -rs PROXMOX_PASSWORD   # silent read keeps the root password out of shell history
export PROXMOX_PASSWORD
export PROXMOX_VALIDATE_CERTS=false   # only needed if the node cert isn't trusted yet
export BWS_ACCESS_TOKEN=<write-enabled machine account token>
export BWS_PROJECT_ID=<homelab project id from bws project list>
ansible-playbook proxmox.yml -e ansible_python_interpreter=$(which python3)
```

The first run mints the token and auto-stores it into the BWS `homelab`
project in the same invocation (see the ADR in `docs/adr/`), so nothing is
captured or committed by hand. Later runs are no-ops.

### Rotating a lost secret

If the secret is lost and the token still exists, force a fresh one with the
same env vars as above plus the regenerate flag. The playbook drops the
user's tokens (this user only ever has `provider`), then mints a new one and
auto-stores the replacement in BWS the same way.

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
