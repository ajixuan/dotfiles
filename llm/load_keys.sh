#!/usr/bin/env bash
# Source this script to export API keys from .gpg files in KEYS_DIR.
# Maps filename bases to hardcoded env var names from nvim ai.lua.

KEYS_DIR="${KEYS_DIR:-$HOME/ki}"

if [[ ! -d "$KEYS_DIR" ]]; then
  echo "Warning: KEYS_DIR=$KEYS_DIR not found" >&2
  return 0 2>/dev/null || exit 0
fi

declare -A KEY_MAP=(
  [openrouter_api_key]=OPENROUTER_API_KEY
  [deepseek_api_key]=DEEPSEEK_API_KEY
  [azure_anthropic_api_key]=AZURE_ANTHROPIC_API_KEY
)

for keyfile in "$KEYS_DIR"/*.gpg; do
  [[ -f "$keyfile" ]] || continue
  name="$(basename "$keyfile" .gpg)"
  env_name="${KEY_MAP[$name]:-}"
  if [[ -z "$env_name" ]]; then
    echo "Warning: no mapping for '$name', skipping" >&2
    continue
  fi
  value="$(gpg --batch --quiet --decrypt "$keyfile" 2>/dev/null)" || {
    echo "Warning: failed to decrypt $keyfile" >&2
    continue
  }
  export "$env_name=$value"
done

unset KEYS_DIR KEY_MAP keyfile name env_name value
