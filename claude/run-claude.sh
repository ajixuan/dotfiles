#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="claude-code"
DOCKERFILE="Dockerfile.claude-code"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="/home/claude/project"

usage() {
    echo "Usage: $0 [--kube] [--azure] <dir1> [dir2] [dir3] ..."
    echo ""
    echo "Bind-mounts each directory into the container's $WORKDIR/<basename>."
    echo "Builds the image from $DOCKERFILE if it doesn't already exist."
    echo ""
    echo "Options:"
    echo "  --kube     Mount kubeconfig into the container"
    echo "  --azure    Mount Azure CLI credentials into the container"
    exit 1
}

# Parse flags
MOUNT_KUBE=false
MOUNT_AZURE=false
DIRS=()
for arg in "$@"; do
    case "$arg" in
        --kube)  MOUNT_KUBE=true ;;
        --azure) MOUNT_AZURE=true ;;
        *)       DIRS+=("$arg") ;;
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

# Credentials are copied into anonymous docker volumes rather than bind-mounted
# from the host.  A bind-mount would require chowning the host path to the
# container UID (needs sudo, and the host files end up owned by that UID),
# whereas a volume can be populated and chowned from inside a helper container
# running as root.  The volumes are deleted on exit so creds don't persist.
CLAUDE_UID="$(docker run --rm --entrypoint id "$IMAGE_NAME" -u)"

VOLUMES_TO_CLEAN=()
cleanup() {
    for vol in "${VOLUMES_TO_CLEAN[@]}"; do
        docker volume rm -f "$vol" >/dev/null 2>&1 || true
    done
}
trap cleanup EXIT

# Stream the source files into the helper via tar on stdin rather than
# bind-mounting the host dir.  Under docker userns-remap, container UID 0 maps
# to a host subuid that can't read $HOME-owned files even if they have 0600,
# so a bind-mount hits EACCES.  Reading happens on the host instead, where we
# own the files.
populate_volume_from_tar() {
    local volume="$1" extract_cmd="$2"
    docker run --rm -i --user 0 --entrypoint sh \
        -v "$volume:/dst" \
        "$IMAGE_NAME" \
        -c "$extract_cmd && chown -R $CLAUDE_UID:$CLAUDE_UID /dst" \
        >/dev/null
}

# --- Azure credentials (opt-in via --azure) ---
AZURE_MOUNT_ARGS=()
if [[ "$MOUNT_AZURE" == true ]]; then
    AZURE_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure}"
    if [[ -d "$AZURE_DIR" ]]; then
        AZURE_VOLUME="$(docker volume create)"
        VOLUMES_TO_CLEAN+=("$AZURE_VOLUME")
        tar -C "$AZURE_DIR" -cf - . \
            | populate_volume_from_tar "$AZURE_VOLUME" \
                "tar -xf - -C /dst && chmod -R u+rwX,go-rwx /dst"
        AZURE_MOUNT_ARGS=(-v "$AZURE_VOLUME:/home/claude/.azure")
    else
        echo "Warning: Azure config dir '$AZURE_DIR' not found. Azure auth may fail." >&2
    fi
fi

# --- Kubeconfig (opt-in via --kube) ---
KUBE_MOUNT_ARGS=()
if [[ "$MOUNT_KUBE" == true ]]; then
    KUBECONFIG_SRC="${KUBECONFIG:-$HOME/.kube/infra-config}"
    if [[ -f "$KUBECONFIG_SRC" ]]; then
        KUBE_VOLUME="$(docker volume create)"
        VOLUMES_TO_CLEAN+=("$KUBE_VOLUME")
        cat "$KUBECONFIG_SRC" \
            | populate_volume_from_tar "$KUBE_VOLUME" \
                "cat > /dst/infra-config && chmod 600 /dst/infra-config"
        KUBE_MOUNT_ARGS=(-v "$KUBE_VOLUME:/home/claude/.kube")
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

docker run --rm -it \
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
