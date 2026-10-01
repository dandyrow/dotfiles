# Proxmox OpenTofu

The `local` datastore is declared here rather than left to the installer,
because the New-H0Ryzen deploy uploads its disk image as
`content_type = "import"` and Proxmox accepts that only on a datastore whose
content list includes it. The installer's `local` does not, so the upload has
nowhere to go. A `lvmthin` store is no help; it takes `images` and `rootdir` and
nothing else.

Proxmox replaces the content list whole rather than merging it, which is why
`storage.tf` names `backup`, `iso` and `vztmpl` next to `import`. Dropping them
would silently cost the node its defaults.

Credentials come from the environment and appear nowhere in this directory. The
provider block is left out because the bpg provider reads them natively, and an
`api_token` argument in HCL is one more thing to keep out of a commit.

| Variable | Value |
| --- | --- |
| `PROXMOX_VE_ENDPOINT` | `https://<node>:8006/`, no `/api2/json` suffix |
| `PROXMOX_VE_API_TOKEN` | `terraform@pve!provider=<secret>`, from BWS |
| `PROXMOX_VE_INSECURE` | `true` only while the node cert is untrusted |

The Ansible bootstrap mints the token and stores it in BWS as
`proxmox-provider-token`, so there is no secret in this repo to fetch first:

```sh
export PROXMOX_VE_ENDPOINT="https://192.168.0.2:8006/"
export PROXMOX_VE_API_TOKEN="terraform@pve!provider=$(bws secret get proxmox-provider-token --project-id "$BWS_PROJECT_ID" --output json | jq -r .value)"
```

## First apply against a node that already has `local`

The PVE installer creates `local` and it is always there, so a first apply
cannot create it. Adopt it instead. This is the only import in the project:

```sh
tofu init
tofu import 'proxmox_storage_directory.local' local
tofu apply
```

Import before apply. Without the import, apply fails because the storage
already exists.

The `create_subdirs` argument cannot set up the import directory here. It runs
when the provider creates a directory storage, and an import adopts an existing
one, so `/var/lib/vz/import` has to come from the PVE installer. Confirm the
node offers the content type before a deploy needs it:

```sh
pvesm status --content import
```

## Total-loss recovery

The live node decides what is true, so recovery does not need a state backup.
[ADR 0006](../../docs/adr/0006-proxmox-node-state-in-opentofu.md) covers why.

1. Install Proxmox. `local` comes back with the installer's defaults.
2. Run the Ansible bootstrap. It recreates `terraform@pve`, the role, the ACL
   and the token, then stores the token in BWS. See `ansible/README.md`.
3. `tofu init`, then the one import above, then `tofu apply`.

Once a resource is declared, state will remember something the fresh node does
not have. Recreate it from the declaration instead of importing it.

State is local and gitignored, since `terraform.tfstate` holds the cloud-init
password hash. Move to a self-hosted backend once it outgrows a single
controller:

```sh
tofu init -migrate-state
```

If that backend is lost too, redo the recovery steps above and push the rebuilt
state back to it. `.terraform.lock.hcl` is committed, so the provider version is
pinned either way.
