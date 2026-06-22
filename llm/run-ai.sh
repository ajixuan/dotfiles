#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="skip-code"
DOCKERFILE="Dockerfile"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="/home/skip/project"

usage() {
    echo "Usage: $0 [--bind] [--kube] [--azure] [--gitconfig] [--memory] [--postgres] [--go] [--rust] [--opencode] [--claude] [--python] [--npm] [--rebuild] <repo1> [repo2] [repo3] ..."
    echo ""
    echo "Each argument must be a git repository. By default, a clone of the repo"
    echo "at HEAD is copied into a named docker volume and mounted at"
    echo "$WORKDIR/<basename>. Volumes are preserved after exit; extraction"
    echo "commands are printed on shutdown so you can copy work back to the host."
    echo ""
    echo "Options:"
    echo "  --bind       Bind-mount each repo directly into the container instead"
    echo "               of cloning into a volume. Edits inside the container"
    echo "               affect the host repo immediately; no extraction needed."
    echo "               Uses --userns=host so container UID matches host UID."
    echo "  --kube       Mount kubeconfig into the container"
    echo "  --azure      Mount Azure CLI credentials into the container"
    echo "  --gitconfig  Mount ~/.gitconfig into the container"
    echo "  --memory     Persist per-project memory dirs across runs by"
    echo "               bind-mounting ~/.skip/projects/<slug>/memory/"
    echo "               from the host. Only memory is shared — settings,"
    echo "               sessions, agents, plugins stay containerized."
    echo "               Implies host userns (UID matching)."
    echo "  --postgres   Start the postgres sidecar (docker-compose.yml) and"
    echo "               attach the skip container to the skip-code-net network"
    echo "  --go         Mount Go toolchain (/usr/local/go) from the host"
    echo "  --rust       Mount Rust toolchain (~/.cargo, ~/.rustup) from the host"
    echo "  --opencode   Mount opencode CLI from the host's npm global install"
    echo "  --claude     Mount Claude Code CLI from the host's npm global install"
    echo "  --python     Mount uv (Python package manager) from the host's PATH"
    echo "  --npm        Mount npm global tools (typescript, tsx, etc.) from the host's npm global install"
    echo "  --rebuild    Force rebuild of the skip-code image"
    exit 1
}

# Parse flags
MOUNT_KUBE=false
MOUNT_AZURE=false
MOUNT_GITCONFIG=false
MOUNT_MEMORY=false
START_POSTGRES=false
REBUILD=false
BIND_MOUNT=false
MOUNT_GO=false
MOUNT_RUST=false
MOUNT_OPENCODE=false
MOUNT_CLAUDE=false
MOUNT_PYTHON=false
MOUNT_NPM=false
DIRS=()
for arg in "$@"; do
    case "$arg" in
        --bind)      BIND_MOUNT=true ;;
        --kube)      MOUNT_KUBE=true ;;
        --azure)     MOUNT_AZURE=true ;;
        --gitconfig) MOUNT_GITCONFIG=true ;;
        --memory)    MOUNT_MEMORY=true ;;
        --postgres)  START_POSTGRES=true ;;
        --go)        MOUNT_GO=true ;;
        --rust)      MOUNT_RUST=true ;;
        --opencode)  MOUNT_OPENCODE=true ;;
        --claude)    MOUNT_CLAUDE=true ;;
        --rebuild)   REBUILD=true ;;
        -h|--help) usage ;;
        *)           DIRS+=("$arg") ;;
    esac
done

# Build image if it doesn't exist or --rebuild was requested. The image's
# in-built skip user is UID 1000 (the node:22-slim base user, renamed).
# Default flow runs as that user; --bind runs as the host UID via
# --userns=host. /home/skip is world-writable so any UID can use it as
# $HOME without a rebuild.
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
# and attach the skip container to the same network (skip-code-net) so it can
# reach them by service name. Opt-in via --postgres; compose state + named
# volumes persist across sessions on purpose (postgres data is reusable).
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
COMPOSE_NETWORK="skip-code-net"
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
    tmpdir="$(mktemp -d /tmp/skip-scratch-XXXXXX)"
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


# All volumes created this run. They're referenced by the exited container
# and can only be removed after `docker rm $CONTAINER_NAME`.
SESSION_VOLUMES=()
# Per-project metadata for cp command generation: "vol<TAB>src<TAB>base".
PROJECT_VOLUMES=()
# Bind-mounted projects (no extraction needed — host already sees changes):
# "src<TAB>base".
PROJECT_BINDS=()

# Credentials and project sources are copied into docker volumes rather
# than bind-mounted from the host. A bind-mount would require chowning the
# host path to the container UID (needs sudo, and host files end up owned
# by that UID), whereas a volume can be populated and chowned from inside a
# helper container running as root.
#
# With --bind, the container needs to write to host files as the host UID.
# Under a daemon with userns-remap enabled, container --user N would get
# remapped to a host subuid that doesn't own the bind-mounted files, so
# --userns=host opts this container out of remapping. Combined with
# --user $(id -u):$(id -g), the in-container UID matches the host UID
# exactly and bind mounts round-trip ownership cleanly.
#
# Caveat: image layers are stored on disk with UIDs remapped through the
# daemon's userns-remap (image UID 1000 lives on host disk as subuid
# 101000-ish). Under --userns=host, the container sees those files at
# their on-disk UID — i.e. not skip. Mirror /home/skip into a fresh
# volume and chown it to the host UID so the running container sees its
# home as skip-owned. The helper also runs with --userns=host so its
# chown writes real host-UID ownership rather than subuid-remapped UIDs.
USER_ARGS=()
USERNS_ARGS=()
HOME_MOUNT_ARGS=()
if [[ "$BIND_MOUNT" == true ]] || [[ "$MOUNT_MEMORY" == true ]]; then
    SKIP_UID="$(id -u)"
    SKIP_GID="$(id -g)"
    USER_ARGS=(--user "$SKIP_UID:$SKIP_GID")
    USERNS_ARGS=(--userns=host)

    HOME_VOLUME="$(docker volume create)"
    SESSION_VOLUMES+=("$HOME_VOLUME")
    docker run --rm --user 0 --userns=host --entrypoint sh \
        -v "$HOME_VOLUME:/dst" \
        "$IMAGE_NAME" \
        -c "cp -a /home/skip/. /dst/ && chown -R $SKIP_UID:$SKIP_GID /dst" \
        >/dev/null
    HOME_MOUNT_ARGS=(-v "$HOME_VOLUME:/home/skip")
else
    SKIP_UID="$(docker run --rm --entrypoint id "$IMAGE_NAME" -u)"
    SKIP_GID="$SKIP_UID"
fi

# The main container is NOT run with --rm, so after it exits the user can
# 'docker cp' project files straight out of it. Nothing is cleaned up
# automatically; the cleanup trap prints the extraction + teardown commands.
CONTAINER_NAME="skip-code-$(date +%s)-$RANDOM"

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
    if [[ ${#PROJECT_BINDS[@]} -gt 0 ]]; then
        echo ""
        echo "Bind-mounted projects (changes are already on host, no extraction needed):"
        for entry in "${PROJECT_BINDS[@]}"; do
            IFS=$'\t' read -r src base <<< "$entry"
            echo "  $base -> $src"
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
    # Inherit USERNS_ARGS so the chown inside the helper sees the same UID
    # namespace as the main container. Without this, --bind runs the main
    # container in host userns but the helper in the daemon's remapped
    # userns, and chown 1000:1000 in the helper produces files owned by
    # host subuid 101000 — which the main container then reads as foreign.
    docker run --rm -i --user 0 --entrypoint sh \
        "${USERNS_ARGS[@]}" \
        -v "$volume:/dst" \
        "$IMAGE_NAME" \
        -c "$extract_cmd && chown -R $SKIP_UID:$SKIP_UID /dst" \
        >/dev/null
}

# --- Project mounts ---
# Default: clone the repo into a throwaway staging dir, copy into a named
# docker volume via the populate helper, mount that volume at
# $WORKDIR/<basename>. Volume is PRESERVED after exit so work can be
# recovered (cleanup trap prints docker cp commands).
#
# With --bind: bind-mount the repo dir directly. Edits inside the container
# affect the host repo immediately. The container runs with --userns=host
# so the container UID matches the host UID.
MOUNT_ARGS=()
for dir in "${DIRS[@]}"; do
    abs_dir="$(cd "$dir" && pwd)"
    base="$(basename "$abs_dir")"

    if [[ "$BIND_MOUNT" == true ]]; then
        PROJECT_BINDS+=("$abs_dir"$'\t'"$base")
        MOUNT_ARGS+=(-v "$abs_dir:$WORKDIR/$base")
        continue
    fi

    stage="$(mktemp -d)"
    git clone --quiet "$abs_dir" "$stage/skip-volume"

    # Sanitize base for docker volume naming (alphanumeric, ., -, _ only)
    safe_base="$(printf '%s' "$base" | tr -c '[:alnum:]._-' '_')"
    vol_name="skip-proj-${safe_base}-$(date +%s)-$RANDOM"
    docker volume create "$vol_name" >/dev/null
    tar -C "$stage/skip-volume" -cf - . \
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
for entry in "${PROJECT_BINDS[@]}"; do
    IFS=$'\t' read -r src base <<< "$entry"
    echo "  $src -> $WORKDIR/$base (bind)"
done

# --- Azure CLI + credentials (opt-in via --azure) ---
AZURE_MOUNT_ARGS=()
if [[ "$MOUNT_AZURE" == true ]]; then
    AZURE_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure}"
    if [[ -d "$AZURE_DIR" ]]; then
        AZURE_VOLUME="$(docker volume create)"
        SESSION_VOLUMES+=("$AZURE_VOLUME")
        tar -C "$AZURE_DIR" -cf - . \
            | populate_volume_from_tar "$AZURE_VOLUME" \
                "tar -xf - -C /dst && chmod -R u+rwX,go-rwx /dst"
        AZURE_MOUNT_ARGS=(-v "$AZURE_VOLUME:/home/skip/.azure")
    else
        echo "Warning: Azure config dir '$AZURE_DIR' not found. Azure auth may fail." >&2
    fi
    # Mount the az binary from the host if available
    if command -v az &>/dev/null; then
        AZURE_MOUNT_ARGS+=(-v "$(command -v az):/usr/local/bin/az:ro")
    else
        echo "Warning: az not found on host PATH. Azure CLI binary mount skipped." >&2
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
        KUBE_MOUNT_ARGS=(-v "$KUBE_VOLUME:/home/skip/.kube")
    else
        echo "Warning: Kubeconfig '$KUBECONFIG_SRC' not found. kubectl may not work." >&2
    fi
fi

# --- Gitconfig (opt-in via --gitconfig) ---
# Volumes become directories, not files, so we can't mount directly at
# /home/skip/.gitconfig. Instead, drop the file into a volume dir and
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
        GITCONFIG_MOUNT_ARGS=(-v "$GITCONFIG_VOLUME:/home/skip/.gitconfig.d")
        GITCONFIG_ENV_ARGS=(-e GIT_CONFIG_GLOBAL=/home/skip/.gitconfig.d/gitconfig)
    else
        echo "Warning: Gitconfig '$GITCONFIG_SRC' not found." >&2
    fi
fi

# --- Global skip config dir (settings, hooks, statusline) ---
# Populated into an anonymous volume rather than bind-mounted so the
# container can write to ~/.skip (memory, session state, etc.) without
# touching the host and without hitting userns-remap permission issues.
# Listed in SESSION_VOLUMES so the cleanup message includes it in the
# 'docker volume rm' line the user runs when tearing the session down.
SKIP_CONFIG_MOUNT_ARGS=()
SKIP_CONFIG_VOLUME="$(docker volume create)"
SESSION_VOLUMES+=("$SKIP_CONFIG_VOLUME")

SKIP_SETTINGS_DIR="$SCRIPT_DIR/skip"
if [[ -d "$SKIP_SETTINGS_DIR" ]] && [[ -n "$(ls -A "$SKIP_SETTINGS_DIR" 2>/dev/null)" ]]; then
    tar -C "$SKIP_SETTINGS_DIR" -cf - . \
        | populate_volume_from_tar "$SKIP_CONFIG_VOLUME" \
            "tar -xf - -C /dst"
fi

GLOBAL_DIR="$SCRIPT_DIR/global"
if [[ -d "$GLOBAL_DIR" ]] && [[ -n "$(ls -A "$GLOBAL_DIR" 2>/dev/null)" ]]; then
    tar -C "$GLOBAL_DIR" -cf - . \
        | populate_volume_from_tar "$SKIP_CONFIG_VOLUME" \
            "tar -xf - -C /dst"
fi

SKIP_CONFIG_MOUNT_ARGS=(-v "$SKIP_CONFIG_VOLUME:/home/skip/.skip")


# --- OpenCode global config dir ---
# Mounts the opencode config and plugins from the dotfiles into
# ~/.config/opencode so opencode can find them inside the container.
OPENCODE_CONFIG_MOUNT_ARGS=()
OPENCODE_CONFIG_VOLUME="$(docker volume create)"
SESSION_VOLUMES+=("$OPENCODE_CONFIG_VOLUME")

OPENCODE_DIR="$SCRIPT_DIR/opencode"
if [[ -d "$OPENCODE_DIR" ]] && [[ -n "$(ls -A "$OPENCODE_DIR" 2>/dev/null)" ]]; then
    tar -C "$OPENCODE_DIR" -chf - . \
        | populate_volume_from_tar "$OPENCODE_CONFIG_VOLUME" \
            "tar -xf - -C /dst"
fi

OPENCODE_CONFIG_MOUNT_ARGS=(-v "$OPENCODE_CONFIG_VOLUME:/home/skip/.config/opencode")

# --- Go toolchain (opt-in via --go) ---
# --- Go toolchain (opt-in via --go) ---
GO_MOUNT_ARGS=()
if [[ "$MOUNT_GO" == true ]]; then
    if [[ -d "/usr/local/go" ]]; then
        GO_MOUNT_ARGS=(-v /usr/local/go:/usr/local/go:ro)
    else
        echo "Warning: /usr/local/go not found on host. Go mount skipped." >&2
    fi
fi

# --- Rust toolchain (opt-in via --rust) ---
RUST_MOUNT_ARGS=()
if [[ "$MOUNT_RUST" == true ]]; then
    if [[ -d "$HOME/.cargo" ]]; then
        RUST_MOUNT_ARGS+=(-v "$HOME/.cargo:/home/skip/.cargo")
    else
        echo "Warning: $HOME/.cargo not found on host. Cargo mount skipped." >&2
    fi
    if [[ -d "$HOME/.rustup" ]]; then
        RUST_MOUNT_ARGS+=(-v "$HOME/.rustup:/home/skip/.rustup")
    fi
fi

# --- OpenCode CLI (opt-in via --opencode) ---
# Instead of baking npm install -g opencode-ai into the image, mount
# the host's global npm install at runtime. Resolve the real bin path
# and mount the package directory so node module resolution works.
OPENCODE_CLI_MOUNT_ARGS=()
if [[ "$MOUNT_OPENCODE" == true ]]; then
    if command -v opencode &>/dev/null; then
        npm_root="$(npm root -g 2>/dev/null || echo /usr/local/lib/node_modules)"
        pkg_dir="$npm_root/opencode-ai"
        if [[ -d "$pkg_dir" ]]; then
            real_bin="$(readlink -f "$(command -v opencode)")"
            echo "  $pkg_dir -> $pkg_dir (ro)"
            OPENCODE_CLI_MOUNT_ARGS+=(-v "$pkg_dir:$pkg_dir:ro")

            wrapper="$(mktemp)"
            cat > "$wrapper" << WRAP
#!/bin/sh
exec node "$real_bin" "\$@"
WRAP
            chmod +x "$wrapper"
            echo "  $real_bin -> /usr/local/bin/opencode (wrapper)"
            OPENCODE_CLI_MOUNT_ARGS+=(-v "$wrapper:/usr/local/bin/opencode:ro")
        fi
    else
        echo "Warning: opencode not found on host PATH. --opencode flag ignored." >&2
    fi
fi

# --- Claude Code CLI (opt-in via --claude) ---
CLAUDE_CLI_MOUNT_ARGS=()
if [[ "$MOUNT_CLAUDE" == true ]]; then
    if command -v claude &>/dev/null; then
        npm_root="$(npm root -g 2>/dev/null || echo /usr/local/lib/node_modules)"
        pkg_dir="$npm_root/@anthropic-ai/claude-code"
        if [[ -d "$pkg_dir" ]]; then
            real_bin="$(readlink -f "$(command -v claude)")"
            echo "  $pkg_dir -> $pkg_dir (ro)"
            CLAUDE_CLI_MOUNT_ARGS+=(-v "$pkg_dir:$pkg_dir:ro")

            wrapper="$(mktemp)"
            cat > "$wrapper" << WRAP
#!/bin/sh
exec node "$real_bin" "\$@"
WRAP
            chmod +x "$wrapper"
            echo "  $real_bin -> /usr/local/bin/claude (wrapper)"
            CLAUDE_CLI_MOUNT_ARGS+=(-v "$wrapper:/usr/local/bin/claude:ro")
        fi
    else
        echo "Warning: claude not found on host PATH. --claude flag ignored." >&2
    fi
fi

# --- Python / uv (opt-in via --python) ---
# Mount the host's uv binary (Python package manager). The container
# already has python3 from apt; uv adds fast package management.
PYTHON_MOUNT_ARGS=()
if [[ "$MOUNT_PYTHON" == true ]]; then
    if command -v uv &>/dev/null; then
        uv_bin="$(command -v uv)"
        echo "  $uv_bin -> /usr/local/bin/uv (ro)"
        PYTHON_MOUNT_ARGS+=(-v "$uv_bin:/usr/local/bin/uv:ro")

        if command -v uvx &>/dev/null; then
            uvx_bin="$(command -v uvx)"
            echo "  $uvx_bin -> /usr/local/bin/uvx (ro)"
            PYTHON_MOUNT_ARGS+=(-v "$uvx_bin:/usr/local/bin/uvx:ro")
        fi

        if [[ -d "$HOME/.cache/uv" ]]; then
            echo "  $HOME/.cache/uv -> /home/skip/.cache/uv"
            PYTHON_MOUNT_ARGS+=(-v "$HOME/.cache/uv:/home/skip/.cache/uv")
        fi
    else
        echo "Warning: uv not found on host PATH. --python flag ignored." >&2
    fi
fi

# --- npm global tools (opt-in via --npm) ---
# Mount the host's npm globally-installed packages (typescript, tsx,
# etc.) so they are available in the container without baking them in.
# The node_modules are mounted at a non-conflicting path and binaries
# get wrapper scripts.
NPM_MOUNT_ARGS=()
NPM_ENV_ARGS=()
if [[ "$MOUNT_NPM" == true ]]; then
    host_npm_root="$(npm root -g 2>/dev/null || echo /usr/local/lib/node_modules)"
    if [[ -d "$host_npm_root" ]]; then
        mount_npm_root="/usr/local/lib/host-npm-global"
        echo "  $host_npm_root -> $mount_npm_root (ro)"
        NPM_MOUNT_ARGS+=(-v "$host_npm_root:$mount_npm_root:ro")
        NPM_ENV_ARGS=(-e NODE_PATH="$mount_npm_root")

        npm_bin_dir="$(npm bin -g 2>/dev/null || echo /usr/local/bin)"
        for bin_path in "$npm_bin_dir"/*; do
            [[ -f "$bin_path" || -L "$bin_path" ]] || continue
            name="$(basename "$bin_path")"
            [[ "$name" =~ ^(node|npm|npx|corepack|opencode|claude)$ ]] && continue

            real_bin="$(readlink -f "$bin_path")"
            suffix="${real_bin#"$host_npm_root"}"
            mounted_bin="$mount_npm_root$suffix"

            wrapper="$(mktemp)"
            cat > "$wrapper" << WRAP
#!/bin/sh
exec node "$mounted_bin" "$@"
WRAP
            chmod +x "$wrapper"
            echo "  $name -> /usr/local/bin/$name (npm global wrapper)"
            NPM_MOUNT_ARGS+=(-v "$wrapper:/usr/local/bin/$name:ro")
        done
    else
        echo "Warning: npm global root not found at $host_npm_root. --npm flag ignored." >&2
    fi
fi

# Build PATH additions for Go and/or Rust. Fetch the container's default
# PATH so toolchain binaries are discoverable without hardcoding.
TOOLCHAIN_ENV_ARGS=()
TOOLCHAIN_PATH_PARTS=()
if [[ "$MOUNT_GO" == true ]] && [[ -d "/usr/local/go" ]]; then
    TOOLCHAIN_PATH_PARTS+=("/usr/local/go/bin")
fi
if [[ "$MOUNT_RUST" == true ]] && [[ -d "$HOME/.cargo" ]]; then
    TOOLCHAIN_PATH_PARTS+=("/home/skip/.cargo/bin")
    CARGO_HOME_ENV=(-e CARGO_HOME=/home/skip/.cargo)
fi
if [[ ${#TOOLCHAIN_PATH_PARTS[@]} -gt 0 ]]; then
    IFS=: toolchain_path="${TOOLCHAIN_PATH_PARTS[*]}"
    container_path="$(docker run --rm --entrypoint bash "$IMAGE_NAME" -c 'echo $PATH' 2>/dev/null)" \
        || container_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    TOOLCHAIN_ENV_ARGS=(-e "PATH=$toolchain_path:$container_path")
fi

# --- Per-project memory dirs (opt-in via --memory) ---
# Bind-mount only ~/.skip/projects/<slug>/memory/ from the host so
# memory persists across container runs while the rest of ~/.skip stays
# isolated in the volume above. The slug encodes the container's project
# path: /home/skip/project/<base> -> -home-skip-project-<base>.
# Requires host userns + UID matching (set above) so writes round-trip.
MEMORY_MOUNT_ARGS=()
if [[ "$MOUNT_MEMORY" == true ]]; then
    project_entries=()
    [[ ${#PROJECT_VOLUMES[@]} -gt 0 ]] && project_entries+=("${PROJECT_VOLUMES[@]}")
    [[ ${#PROJECT_BINDS[@]} -gt 0 ]] && project_entries+=("${PROJECT_BINDS[@]}")
    mem_parent_paths=()
    for entry in "${project_entries[@]}"; do
        # base is the last tab-separated field in both array formats
        base="${entry##*$'\t'}"
        slug="-home-skip-project-${base}"
        host_mem="$HOME/.skip/projects/$slug/memory"
        mkdir -p "$host_mem"
        MEMORY_MOUNT_ARGS+=(-v "$host_mem:/home/skip/.skip/projects/$slug/memory")
        mem_parent_paths+=("projects/$slug/memory")
    done
    # Pre-create the parent dirs inside SKIP_CONFIG_VOLUME with skip
    # ownership. Without this, Docker materializes the bind-mount target
    # by creating projects/ and projects/<slug>/ inside the volume as
    # root, and the container user can't traverse or write siblings.
    if [[ ${#mem_parent_paths[@]} -gt 0 ]]; then
        mkdir_args=()
        for p in "${mem_parent_paths[@]}"; do
            mkdir_args+=("/dst/$p")
        done
        docker run --rm --user 0 --entrypoint sh \
            "${USERNS_ARGS[@]}" \
            -v "$SKIP_CONFIG_VOLUME:/dst" \
            "$IMAGE_NAME" \
            -c "mkdir -p ${mkdir_args[*]} && chown -R $SKIP_UID:$SKIP_UID /dst/projects" \
            >/dev/null
    fi
fi

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
        -e PGUSER=skip
        -e PGPASSWORD=skip
        -e PGDATABASE=skip
    )
fi

docker run -it \
    --name "$CONTAINER_NAME" \
    --tmpfs /tmp:exec,nosuid,size=1g \
    --cap-drop=ALL \
    --security-opt=no-new-privileges \
    --memory=4g \
    --cpus=2 \
    --pids-limit=256 \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    -e DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-}" \
    -e CLAUDE_CODE_USE_FOUNDRY=1 \
    -e ANTHROPIC_FOUNDRY_RESOURCE=ia-foundry-coding-prod-eus2 \
    -e AZURE_TOKEN_CREDENTIALS=dev \
    -e AZURE_CORE_ENCRYPT_TOKEN_CACHE=false \
    "${TOOLCHAIN_ENV_ARGS[@]}" \
    "${NPM_ENV_ARGS[@]}" \
    "${CARGO_HOME_ENV[@]}" \
    "${USER_ARGS[@]}" \
    "${USERNS_ARGS[@]}" \
    "${HOME_MOUNT_ARGS[@]}" \
    "${POSTGRES_ENV_ARGS[@]}" \
    "${GITCONFIG_ENV_ARGS[@]}" \
    "${NETWORK_ARGS[@]}" \
    "${AZURE_MOUNT_ARGS[@]}" \
    "${KUBE_MOUNT_ARGS[@]}" \
    "${GITCONFIG_MOUNT_ARGS[@]}" \
    "${SKIP_CONFIG_MOUNT_ARGS[@]}" \
    "${OPENCODE_CONFIG_MOUNT_ARGS[@]}" \
    "${MEMORY_MOUNT_ARGS[@]}" \
    "${GO_MOUNT_ARGS[@]}" \
    "${RUST_MOUNT_ARGS[@]}" \
    "${OPENCODE_CLI_MOUNT_ARGS[@]}" \
    "${CLAUDE_CLI_MOUNT_ARGS[@]}" \
    "${PYTHON_MOUNT_ARGS[@]}" \
    "${NPM_MOUNT_ARGS[@]}" \
    "${MOUNT_ARGS[@]}" \
    "$IMAGE_NAME"
