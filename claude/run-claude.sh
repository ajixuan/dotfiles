#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="claude-code"
DOCKERFILE="Dockerfile.claude-code"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="/home/claude/project"

usage() {
    echo "Usage: $0 [--kube] [--azure] [--postgres] [--rebuild] <repo1> [repo2] [repo3] ..."
    echo ""
    echo "Each argument must be a git repository. A clone of the repo at HEAD"
    echo "is copied into a named docker volume and mounted at $WORKDIR/<basename>."
    echo "Volumes are preserved after exit; extraction commands are printed on"
    echo "shutdown so you can copy work back to the host."
    echo ""
    echo "Options:"
    echo "  --kube       Mount kubeconfig into the container"
    echo "  --azure      Mount Azure CLI credentials into the container"
    echo "  --gitconfig  Mount ~/.gitconfig into the container"
    echo "  --postgres   Start the postgres sidecar (docker-compose.yml) and"
    echo "               attach the claude container to the claude-net network"
    echo "  --rebuild    Force rebuild of the claude-code image"
    exit 1
}

# Parse flags
MOUNT_KUBE=false
MOUNT_AZURE=false
MOUNT_GITCONFIG=false
START_POSTGRES=false
REBUILD=false
DIRS=()
for arg in "$@"; do
    case "$arg" in
        --kube)      MOUNT_KUBE=true ;;
        --azure)     MOUNT_AZURE=true ;;
        --gitconfig) MOUNT_GITCONFIG=true ;;
        --postgres)  START_POSTGRES=true ;;
        --rebuild)   REBUILD=true ;;
        *)           DIRS+=("$arg") ;;
    esac
done

# Build image if it doesn't exist or --rebuild was requested
if [[ "$REBUILD" == true ]] || ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    if [[ "$REBUILD" == true ]]; then
        echo "Rebuilding image '$IMAGE_NAME'..."
    else
        echo "Image '$IMAGE_NAME' not found. Building..."
    fi
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/$DOCKERFILE" "$SCRIPT_DIR"
else
    echo "Image '$IMAGE_NAME' already exists."
fi

# Bring up sidecar services defined in docker-compose.yml (postgres, etc.)
# and attach the claude container to the same network (claude-net) so it can
# reach them by service name. Opt-in via --postgres; compose state + named
# volumes persist across sessions on purpose (postgres data is reusable).
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
COMPOSE_NETWORK="claude-net"
if [[ "$START_POSTGRES" == true ]]; then
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        echo "Error: --postgres requested but $COMPOSE_FILE not found" >&2
        exit 1
    fi
    echo "Starting sidecar services from $COMPOSE_FILE..."
    docker compose -f "$COMPOSE_FILE" up -d --wait
fi

# Default to a fresh throwaway git repo if no directories given, so the
# worktree pipeline below has something to operate on.
if [[ ${#DIRS[@]} -lt 1 ]]; then
    tmpdir="$(mktemp -d /tmp/claude-scratch-XXXXXX)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" commit -q --allow-empty -m "init"
    echo "No directories specified. Using $tmpdir"
    DIRS=("$tmpdir")
fi

# Validate each argument is an existing git repository
for dir in "${DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo "Error: '$dir' is not a directory" >&2
        exit 1
    fi
    if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: '$dir' is not a git repository" >&2
        exit 1
    fi
done


# Credentials and project sources are copied into docker volumes rather
# than bind-mounted from the host. A bind-mount would require chowning the
# host path to the container UID (needs sudo, and host files end up owned
# by that UID), whereas a volume can be populated and chowned from inside a
# helper container running as root.
CLAUDE_UID="$(docker run --rm --entrypoint id "$IMAGE_NAME" -u)"

# The main container is NOT run with --rm, so after it exits the user can
# 'docker cp' project files straight out of it. Nothing is cleaned up
# automatically; the cleanup trap prints the extraction + teardown commands.
CONTAINER_NAME="claude-code-$(date +%s)-$RANDOM"

# All volumes created this run. They're referenced by the exited container
# and can only be removed after `docker rm $CONTAINER_NAME`.
SESSION_VOLUMES=()
# Per-project metadata for cp command generation: "vol<TAB>src<TAB>base".
PROJECT_VOLUMES=()
cleanup() {
    echo ""
    echo "Session preserved. Container: $CONTAINER_NAME"
    if [[ ${#PROJECT_VOLUMES[@]} -gt 0 ]]; then
        echo ""
        echo "Copy project work back to the host (runs against the exited container):"
        for entry in "${PROJECT_VOLUMES[@]}"; do
            IFS=$'\t' read -r vol src base <<< "$entry"
            echo ""
            echo "  # $base  (source: $src)"
            echo "  DST=/path/on/host  # change this"
            echo "  mkdir -p \"\$DST\" && docker cp $CONTAINER_NAME:$WORKDIR/$base/. \"\$DST\""
            echo "  sudo chown -R \$(id -u):\$(id -g) \"\$DST\"   # reclaim from userns subuid"
        done
    fi
    echo ""
    echo "When done, remove the container and its volumes:"
    echo "  docker rm $CONTAINER_NAME"
    if [[ ${#SESSION_VOLUMES[@]} -gt 0 ]]; then
        echo "  docker volume rm ${SESSION_VOLUMES[*]}"
    fi
    if [[ "$START_POSTGRES" == true ]]; then
        echo ""
        echo "Sidecar services (postgres, ...) are left running. To stop them:"
        echo "  docker compose -f $COMPOSE_FILE down"
        echo "To stop and wipe their data volumes as well:"
        echo "  docker compose -f $COMPOSE_FILE down -v"
    fi
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

# --- Project mounts: git clone -> named docker volume ---
# For each repo arg, clone it into a throwaway staging directory, copy the
# clone into a named docker volume via the populate helper, then discard
# the staging dir.  The volume is mounted at $WORKDIR/<basename> and is
# PRESERVED after exit so work done inside the container can be recovered
# (the cleanup trap prints a command to extract it to a host path).
MOUNT_ARGS=()
for dir in "${DIRS[@]}"; do
    abs_dir="$(cd "$dir" && pwd)"
    base="$(basename "$abs_dir")"

    stage="$(mktemp -d)"
    git clone --quiet "$abs_dir" "$stage/claude-volume"

    # Sanitize base for docker volume naming (alphanumeric, ., -, _ only)
    safe_base="$(printf '%s' "$base" | tr -c '[:alnum:]._-' '_')"
    vol_name="claude-proj-${safe_base}-$(date +%s)-$RANDOM"
    docker volume create "$vol_name" >/dev/null
    tar -C "$stage/claude-volume" -cf - . \
        | populate_volume_from_tar "$vol_name" "tar -xf - -C /dst"
    rm -rf "$stage"

    PROJECT_VOLUMES+=("$vol_name"$'\t'"$abs_dir"$'\t'"$base")
    MOUNT_ARGS+=(-v "$vol_name:$WORKDIR/$base")
done

echo "Running container with mounts:"
for entry in "${PROJECT_VOLUMES[@]}"; do
    IFS=$'\t' read -r vol src base <<< "$entry"
    echo "  $src -> $WORKDIR/$base (volume: $vol)"
done

# --- Azure credentials (opt-in via --azure) ---
AZURE_MOUNT_ARGS=()
if [[ "$MOUNT_AZURE" == true ]]; then
    AZURE_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure}"
    if [[ -d "$AZURE_DIR" ]]; then
        AZURE_VOLUME="$(docker volume create)"
        SESSION_VOLUMES+=("$AZURE_VOLUME")
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
        SESSION_VOLUMES+=("$KUBE_VOLUME")
        cat "$KUBECONFIG_SRC" \
            | populate_volume_from_tar "$KUBE_VOLUME" \
                "cat > /dst/infra-config && chmod 600 /dst/infra-config"
        KUBE_MOUNT_ARGS=(-v "$KUBE_VOLUME:/home/claude/.kube")
    else
        echo "Warning: Kubeconfig '$KUBECONFIG_SRC' not found. kubectl may not work." >&2
    fi
fi

# --- Gitconfig (opt-in via --gitconfig) ---
# Volumes become directories, not files, so we can't mount directly at
# /home/claude/.gitconfig. Instead, drop the file into a volume dir and
# point git at it via GIT_CONFIG_GLOBAL.
GITCONFIG_MOUNT_ARGS=()
GITCONFIG_ENV_ARGS=()
if [[ "$MOUNT_GITCONFIG" == true ]]; then
    GITCONFIG_SRC="$HOME/.gitconfig"
    if [[ -f "$GITCONFIG_SRC" ]]; then
        GITCONFIG_VOLUME="$(docker volume create)"
        SESSION_VOLUMES+=("$GITCONFIG_VOLUME")
        cat "$GITCONFIG_SRC" \
            | populate_volume_from_tar "$GITCONFIG_VOLUME" \
                "cat > /dst/gitconfig && chmod 644 /dst/gitconfig"
        GITCONFIG_MOUNT_ARGS=(-v "$GITCONFIG_VOLUME:/home/claude/.gitconfig.d")
        GITCONFIG_ENV_ARGS=(-e GIT_CONFIG_GLOBAL=/home/claude/.gitconfig.d/gitconfig)
    else
        echo "Warning: Gitconfig '$GITCONFIG_SRC' not found." >&2
    fi
fi

# --- Global Claude config dir (settings, hooks, statusline) ---
# Populated into an anonymous volume rather than bind-mounted so the
# container can write to ~/.claude (memory, session state, etc.) without
# touching the host and without hitting userns-remap permission issues.
# Listed in SESSION_VOLUMES so the cleanup message includes it in the
# 'docker volume rm' line the user runs when tearing the session down.
CLAUDE_CONFIG_MOUNT_ARGS=()
CLAUDE_CONFIG_VOLUME="$(docker volume create)"
SESSION_VOLUMES+=("$CLAUDE_CONFIG_VOLUME")

if [[ -f "$HOME/.claude/settings.json" ]]; then
    tar -C "$HOME/.claude" -cf - settings.json \
        | populate_volume_from_tar "$CLAUDE_CONFIG_VOLUME" \
            "tar -xf - -C /dst"
fi

GLOBAL_DIR="$SCRIPT_DIR/global"
if [[ -d "$GLOBAL_DIR" ]] && [[ -n "$(ls -A "$GLOBAL_DIR" 2>/dev/null)" ]]; then
    tar -C "$GLOBAL_DIR" -cf - . \
        | populate_volume_from_tar "$CLAUDE_CONFIG_VOLUME" \
            "tar -xf - -C /dst"
fi

CLAUDE_CONFIG_MOUNT_ARGS=(-v "$CLAUDE_CONFIG_VOLUME:/home/claude/.claude")

# Attach to the compose-managed network and inject PG* env vars so psql /
# standard postgres client libraries can reach the sidecar by service name.
# Gated on --postgres; without it, falls back to docker's default bridge
# network and no postgres env is set.
NETWORK_ARGS=()
POSTGRES_ENV_ARGS=()
if [[ "$START_POSTGRES" == true ]]; then
    NETWORK_ARGS=(--network "$COMPOSE_NETWORK")
    POSTGRES_ENV_ARGS=(
        -e PGHOST=postgres
        -e PGPORT=5432
        -e PGUSER=claude
        -e PGPASSWORD=claude
        -e PGDATABASE=claude
    )
fi

docker run -it \
    --name "$CONTAINER_NAME" \
    --tmpfs /tmp:noexec,nosuid,size=1g \
    --cap-drop=ALL \
    --security-opt=no-new-privileges \
    --memory=4g \
    --cpus=2 \
    --pids-limit=256 \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    "${POSTGRES_ENV_ARGS[@]}" \
    "${GITCONFIG_ENV_ARGS[@]}" \
    "${NETWORK_ARGS[@]}" \
    "${AZURE_MOUNT_ARGS[@]}" \
    "${KUBE_MOUNT_ARGS[@]}" \
    "${GITCONFIG_MOUNT_ARGS[@]}" \
    "${CLAUDE_CONFIG_MOUNT_ARGS[@]}" \
    "${MOUNT_ARGS[@]}" \
    "$IMAGE_NAME"
