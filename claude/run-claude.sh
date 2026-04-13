#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="claude-code"
DOCKERFILE="Dockerfile.claude-code"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="/home/claude/project"

usage() {
    echo "Usage: $0 [--kube] <dir1> [dir2] [dir3] ..."
    echo ""
    echo "Bind-mounts each directory into the container's $WORKDIR/<basename>."
    echo "Builds the image from $DOCKERFILE if it doesn't already exist."
    echo ""
    echo "Options:"
    echo "  --kube    Mount kubeconfig into the container"
    exit 1
}

# Parse flags
MOUNT_KUBE=false
DIRS=()
for arg in "$@"; do
    case "$arg" in
        --kube) MOUNT_KUBE=true ;;
        *)      DIRS+=("$arg") ;;
    esac
done

# Default to a temp directory if no directories given
if [[ ${#DIRS[@]} -lt 1 ]]; then
    tmpdir="$(mktemp -d /tmp/claude-XXXXXX)"
    echo "No directories specified. Using $tmpdir"
    DIRS=("$tmpdir")
fi

# Validate all arguments are existing directories
for dir in "${DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo "Error: '$dir' is not a directory" >&2
        exit 1
    fi
done

# Build image if it doesn't exist
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Image '$IMAGE_NAME' not found. Building..."
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/$DOCKERFILE" "$SCRIPT_DIR"
else
    echo "Image '$IMAGE_NAME' already exists."
fi

# Assemble bind-mount flags
MOUNT_ARGS=()
for dir in "${DIRS[@]}"; do
    abs_dir="$(cd "$dir" && pwd)"
    base="$(basename "$abs_dir")"
    MOUNT_ARGS+=(-v "$abs_dir:$WORKDIR/$base")
done

echo "Running container with mounts:"
for dir in "${DIRS[@]}"; do
    abs_dir="$(cd "$dir" && pwd)"
    base="$(basename "$abs_dir")"
    echo "  $abs_dir -> $WORKDIR/$base"
done

# Copy Azure CLI credentials into a tmpdir and mount that (writable) into
# the container.  MSAL needs to create lock files and refresh tokens, so a
# read-only bind-mount of the host dir fails.  Copying keeps the host
# credentials untouched while giving az a working cache inside the container.
CLAUDE_UID="$(docker run --rm --entrypoint id claude-code -u)"

# --- Azure credentials (copied to a writable tmpdir) ---
AZURE_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure}"
AZURE_MOUNT_ARGS=()
AZURE_TMPDIR=""
if [[ -d "$AZURE_DIR" ]]; then
    AZURE_TMPDIR="$(mktemp -d /tmp/claude-azure-XXXXXX)"
    cp -r "$AZURE_DIR"/. "$AZURE_TMPDIR"/
    chmod -R u+rwX,go-rwx "$AZURE_TMPDIR"
    sudo chown -R "$CLAUDE_UID:$CLAUDE_UID" "$AZURE_TMPDIR"
    AZURE_MOUNT_ARGS=(-v "$AZURE_TMPDIR:/home/claude/.azure:ro")
else
    echo "Warning: Azure config dir '$AZURE_DIR' not found. Azure auth may fail." >&2
fi

# --- Kubeconfig (opt-in via --kube, copied to a writable tmpdir) ---
KUBE_MOUNT_ARGS=()
KUBE_TMPDIR=""
if [[ "$MOUNT_KUBE" == true ]]; then
    KUBECONFIG_SRC="${KUBECONFIG:-$HOME/.kube/infra-config}"
    if [[ -f "$KUBECONFIG_SRC" ]]; then
        KUBE_TMPDIR="$(mktemp -d /tmp/claude-kube-XXXXXX)"
        cp "$KUBECONFIG_SRC" "$KUBE_TMPDIR/infra-config"
        chmod 600 "$KUBE_TMPDIR/infra-config"
        sudo chown -R "$CLAUDE_UID:$CLAUDE_UID" "$KUBE_TMPDIR"
        KUBE_MOUNT_ARGS=(-v "$KUBE_TMPDIR:/home/claude/.kube:ro")
    else
        echo "Warning: Kubeconfig '$KUBECONFIG_SRC' not found. kubectl may not work." >&2
    fi
fi

# --- Global Claude settings (read-only) ---
SETTINGS_MOUNT_ARGS=()
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$CLAUDE_SETTINGS" ]]; then
    SETTINGS_MOUNT_ARGS=(-v "$CLAUDE_SETTINGS:/home/claude/.claude/settings.json:ro")
fi

# Clean up temp dirs when the container exits
trap 'sudo rm -rf "$AZURE_TMPDIR" "$KUBE_TMPDIR"' EXIT

exec docker run --rm -it \
    --read-only \
    --tmpfs /tmp:noexec,nosuid,size=256m \
    --cap-drop=ALL \
    --security-opt=no-new-privileges \
    --memory=4g \
    --cpus=2 \
    --pids-limit=256 \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    "${AZURE_MOUNT_ARGS[@]}" \
    "${KUBE_MOUNT_ARGS[@]}" \
    "${SETTINGS_MOUNT_ARGS[@]}" \
    "${MOUNT_ARGS[@]}" \
    "$IMAGE_NAME"
