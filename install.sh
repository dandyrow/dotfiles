#!/usr/bin/env bash
set -euo pipefail

# install.sh — bootstrap a NixOS host using nixos-anywhere.
#
# Usage: ./install.sh <host> <target-ip> <secrets-dir>
#
#   host        — NixOS configuration name (e.g. DansSpectre, New-H0Ryzen)
#   target-ip   — IP address of the target machine (must be booted into a NixOS live ISO)
#   secrets-dir — path to a directory containing etc/secrets/dandyrow-password
#                 (bcrypt-hashed password, generated with: mkpasswd -m bcrypt)
#
# Example:
#   ./install.sh DansSpectre 192.168.1.100 ./secrets

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <host> <target-ip> <secrets-dir>" >&2
  exit 1
fi

HOST="$1"
TARGET_IP="$2"
SECRETS_DIR="$3"

if [[ ! -f "${SECRETS_DIR}/etc/secrets/dandyrow-password" ]]; then
  echo "Error: ${SECRETS_DIR}/etc/secrets/dandyrow-password not found." >&2
  echo "Generate with: mkpasswd -m bcrypt" >&2
  exit 1
fi

echo "Installing NixOS (${HOST}) on ${TARGET_IP}..."

nix run nixpkgs#nixos-anywhere -- \
  --flake ".#${HOST}" \
  --extra-files "${SECRETS_DIR}" \
  "root@${TARGET_IP}"
