#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <project/subdir> <host_dir>"
    echo ""
    echo "Copy the contents of /home/claude/<project/subdir> out of the most"
    echo "recently created claude-code-* container into <host_dir> on the host."
    echo "<host_dir> is created if it does not exist."
    exit 1
}

[[ $# -eq 2 ]] || usage

SRC="${1#/}"
DST="$2"

# docker ps -a lists newest first by default, so head -n1 picks the latest run.
CONTAINER="$(docker ps -a --filter 'name=^claude-code-' --format '{{.Names}}' | head -n1)"
if [[ -z "$CONTAINER" ]]; then
    echo "Error: no claude-code-* container found" >&2
    exit 1
fi

mkdir -p "$DST"

echo "Copying $CONTAINER:/home/claude/$SRC/. -> $DST"
docker cp "$CONTAINER:/home/claude/project/$SRC/." "$DST"

echo "Done. If files are owned by a userns subuid, reclaim them with:"
echo "  sudo chown -R $(id -u):$(id -g) $DST"
