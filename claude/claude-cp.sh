#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 [-r|--reverse] [-c|--container <name>] <project/subdir> <host_dir>"
    echo ""
    echo "Copy the contents of /home/claude/project/<project/subdir> out of the"
    echo "most recently created claude-code-* container into <host_dir> on the"
    echo "host. <host_dir> is created if it does not exist."
    echo ""
    echo "With -r/--reverse, copy the contents of <host_dir> on the host into"
    echo "/home/claude/project/<project/subdir> in the container instead."
    echo ""
    echo "With -c/--container <name>, target the named container instead of the"
    echo "most recently created claude-code-* container."
    exit 1
}

REVERSE=0
CONTAINER=""
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--reverse)
            REVERSE=1
            shift
            ;;
        -c|--container)
            [[ $# -ge 2 ]] || usage
            CONTAINER="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done
            ;;
        -*)
            echo "Error: unknown flag: $1" >&2
            usage
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

[[ ${#POSITIONAL[@]} -eq 2 ]] || usage

SUBDIR="${POSITIONAL[0]#/}"
HOST_DIR="${POSITIONAL[1]}"

if [[ -n "$CONTAINER" ]]; then
    if ! docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER"; then
        echo "Error: container not found: $CONTAINER" >&2
        exit 1
    fi
else
    # docker ps -a lists newest first by default, so head -n1 picks the latest run.
    CONTAINER="$(docker ps -a --filter 'name=^claude-code-' --format '{{.Names}}' | head -n1)"
    if [[ -z "$CONTAINER" ]]; then
        echo "Error: no claude-code-* container found" >&2
        exit 1
    fi
fi

CONTAINER_PATH="/home/claude/project/$SUBDIR"

if [[ $REVERSE -eq 1 ]]; then
    if [[ ! -d "$HOST_DIR" ]]; then
        echo "Error: host directory does not exist: $HOST_DIR" >&2
        exit 1
    fi
    docker exec "$CONTAINER" mkdir -p "$CONTAINER_PATH"
    echo "Copying $HOST_DIR/. -> $CONTAINER:$CONTAINER_PATH"
    docker cp "$HOST_DIR/." "$CONTAINER:$CONTAINER_PATH"
    echo "Done."
else
    mkdir -p "$HOST_DIR"
    echo "Copying $CONTAINER:$CONTAINER_PATH/. -> $HOST_DIR"
    docker cp "$CONTAINER:$CONTAINER_PATH/." "$HOST_DIR"
    echo "Done. If files are owned by a userns subuid, reclaim them with:"
    echo "  sudo chown -R $(id -u):$(id -g) $HOST_DIR"
fi
