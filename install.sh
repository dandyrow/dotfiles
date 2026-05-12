#!/usr/bin/env bash
set -euo pipefail

# install.sh — bootstrap a NixOS host using nixos-anywhere.
#
# Usage: ./install.sh [--build-on-remote] <host> <target-ip> <secrets-dir>
#
#   --build-on-remote  — build and download packages on the target machine
#                        rather than locally. Useful on slow or proxied connections.
#   host               — NixOS configuration name (e.g. DansSpectre, New-H0Ryzen)
#   target-ip          — IP address of the target machine (must be booted into a NixOS live ISO)
#   secrets-dir        — path to a directory containing etc/secrets/dandyrow-password
#                        (bcrypt-hashed password, generated with: mkpasswd -m bcrypt)
#
# Example:
#   ./install.sh DansSpectre 192.168.1.100 ./secrets
#   ./install.sh --build-on-remote DansSpectre 192.168.1.100 ./secrets

BUILD_ON_REMOTE=""

if [[ "${1:-}" == "--build-on-remote" ]]; then
  BUILD_ON_REMOTE="--build-on-remote"
  shift
fi

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 [--build-on-remote] <host> <target-ip> <secrets-dir>" >&2
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
  ${BUILD_ON_REMOTE:+--build-on-remote} \
  --flake "$(dirname "$0")#${HOST}" \
  --extra-files "${SECRETS_DIR}" \
  "root@${TARGET_IP}"
