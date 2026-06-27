#!/usr/bin/env bash
# Outputs KEY=VALUE lines for each .gpg file in KEYS_DIR.
# The filename (minus .gpg suffix) is uppercased to get the env var name.
set -euo pipefail

KEYS_DIR="${KEYS_DIR:-$HOME/ki}"

if [[ ! -d "$KEYS_DIR" ]]; then
  echo "Warning: KEYS_DIR=$KEYS_DIR not found" >&2
  exit 0
fi

for keyfile in "$KEYS_DIR"/*.gpg; do
  [[ -f "$keyfile" ]] || continue
  name="$(basename "$keyfile" .gpg)"
  env_name="$(echo "$name" | tr '[:lower:]' '[:upper:]')"
  value="$(gpg --batch --quiet --decrypt "$keyfile" 2>/dev/null)" || {
    echo "Warning: failed to decrypt $keyfile" >&2
    continue
  }
  echo "$env_name=$value"
done
