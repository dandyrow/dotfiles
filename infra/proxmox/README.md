# Proxmox OpenTofu

Declarative state for the Proxmox node. Starts with the `local` datastore,
because the New-H0Ryzen deploy uploads its disk image as
`content_type = "import"` and Proxmox only accepts that on a datastore whose
content list includes it. `local` is the only local datastore that can: a
`lvmthin` store accepts `images` and `rootdir` only.

Credentials come from the environment and appear nowhere in this directory. The
provider block is omitted on purpose — the bpg provider reads them natively, and
an `api_token` argument in HCL would be one more thing to keep out of a commit.

| Variable | Value |
| --- | --- |
| `PROXMOX_VE_ENDPOINT` | `https://<node>:8006/` — no `/api2/json` suffix |
| `PROXMOX_VE_API_TOKEN` | `terraform@pve!provider=<secret>`, from BWS |
| `PROXMOX_VE_INSECURE` | `true` only while the node cert is untrusted |

The token is minted by the Ansible bootstrap and stored in BWS under
`proxmox-provider-token`, so a fresh clone has nothing to bootstrap:

```sh
export PROXMOX_VE_ENDPOINT="https://192.168.0.2:8006/"
export PROXMOX_VE_API_TOKEN="terraform@pve!provider=$(bws secret get proxmox-provider-token --project-id "$BWS_PROJECT_ID" --output json | jq -r .value)"
```

## First apply against a node that already has `local`

`local` is created by the PVE installer and always exists, so it cannot be
created by a first apply — it has to be adopted. This is the one import in the
project:

```sh
tofu init
tofu import 'proxmox_storage_directory.local' local
tofu apply
```

Import before apply. Without it the plan fails with the storage already
existing.

## Total-loss recovery

The live node is the source of truth, not the state file, so recovery never
depends on having kept state:

1. Install Proxmox. `local` comes back with the installer's defaults.
2. Run the Ansible bootstrap, which recreates `terraform@pve`, its role, the
   ACL, and the token, and stores the token in BWS. See `ansible/README.md`.
3. `tofu init`, then the one import above, then `tofu apply`.

A resource that state remembers but the fresh node does not have — the VM, once
it is declared — is recreated from the declaration rather than imported. That is
deliberate: adopting a half-configured node is how drift gets inherited, whereas
a recreated VM is exactly what this repo says it should be.

## State

Local and gitignored, which is safe precisely because an import can always
re-derive it. `terraform.tfstate` holds the cloud-init password hash, so it does
not belong in the repo even though the repo is private.

Moving to a self-hosted backend later, when the state outgrows one controller:

```sh
tofu init -migrate-state
```

If that backend is itself lost, fall back to the recovery steps above and push
the rebuilt state back. `.terraform.lock.hcl` is committed, so the provider
version is pinned either way.

## Not here yet

The New-H0Ryzen VM, its hardware mappings, and the pool. Those are the deploy
tickets on the map at #187.
