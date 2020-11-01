#!/bin/bash
build_deps="${BUILD_DEPS:-true}"
static="${STATIC:-true}"
tmp_dir="${TMP_DIR:-${HOME}/tmp/artifacts}"
build_dir="${BUILD_DIR:-/usr/local}"
orig_path="${PATH}"

# Environment Varibales
PATH="${PATH}:${build_dir}/bin"
export CARGO_HOME="${BUILD_DIR:-${HOME}}/.cargo"
export RUSTUP_HOME="${BUILD_DIR:-${HOME}}/.cargo"

# Source build variables
. "${script_dir}/build_env.sh"

# restore PATH on exit
trap "PATH=\"${orig_path}\"" EXIT SIGINT SIGTERM

mkdir -p "${build_dir}"
mkdir -p "${tmp_dir}"

###############
# Helpers
function std_build {
  local _pkg_name="${1}"
  local _extra_config_flags=(${2:-})

  ( cd "${tmp_dir}/${_pkg_name}"   && \
    tar xvf ${_pkg_name}.tar.gz    && \
    cd ${_pkg_name}-*/             && \
    [ -f "./configure" ] && ./configure "--prefix=${build_dir}" "${_extra_config_flags[@]}" ||\
    make && make install )
}

# Curl and verify
function curls {
  local _url="${1}"
  local _output="${2}"
  local _asf_url="${3:-}"
  local _import_key_url="${4:-}"

  if [ -n "${_import_key_url}" ]; then
    echo "importing key from ${_import_key_url}"
    curl -LsSf "${_import_key_url}" -o /tmp/tmp.key
    gpg --import /tmp/tmp.key
    rm /tmp/tmp.key
  fi

  if [ ! -f "${_output}" ]; then
    echo "downloading ${_url}"
    curl -LsSf "${_url}" --create-dirs -o "${_output}"
    if [ -n "${_asf_url}" ]; then
      echo "verifying with key from ${_asf_url}"
      curl -LsSf "${_asf_url}" --create-dirs -o "${_output}.asf"
      gpg --verify "${_output}.asf"
    fi
  fi
}

# Build deps
if ${build_deps}; then
  # build autoconf
  if ! [ -f "${build_dir}/bin/autoconf" ] ; then
    curls "${autoconf_url}" "${tmp_dir}/autoconf/autoconf.tar.gz"
    std_build 'autoconf'
  fi

  # build automake
  if ! [ -f "${build_dir}/bin/aclocal" ] ; then
    curls "${automake_url}" "${tmp_dir}/automake/automake.tar.gz"
    std_build 'automake'
  fi

  # build pkg-config
  if ! [ -f "${build_dir}/bin/pkg-config" ] ; then
    curls "${pkgconfig_url}" "${tmp_dir}/pkg-config/pkg-config.tar.gz"
    std_build 'pkg-config' '--with-internal-glib'
  fi

  # build bison
  # curls "${bison_url}" "${tmp_dir}/bison/bison.tar.gz"
  # std_build 'bison'
fi

# build ripgrep
if ! [ -f "${build_dir}/bin/rg" ] ; then

  # Build cargo
  if ! [ -f "${build_dir}/bin/cargo" ] ; then
    echo "Building rust"
    curl --proto '=https' --tlsv1.2 -sSf "${rust_url}" | bash -s -- -y
    #"${build_dir}/rustup" toolchain install nightly --allow-downgrade --profile minimal --component cargo

    # If building in system standard directory, also write cargo home
    [ -z "${BUILD_DIR}" ] && sed -i '/^\# Environment variables/a PATH=\$PATH:'"${CARGO_HOME}"'\/.cargo\/bin' "${HOME}/.bashrc"
  fi

  echo "Building ripgrep"
  [ ! -d "${tmp_dir}/ripgrep" ] && git clone "${ripgrep_url}" "${tmp_dir}/ripgrep"
  ( cd "${tmp_dir}/ripgrep" && \
    cargo build --release   && \
    cp ./target/release/rg "${HOME}/bin" )
fi

# build tmux
if ! [ -f "${build_dir}/bin/tmux" ] ; then

  # build libevent
  if ! [ -f ${build_dir}/lib/libevent.a ]; then
    curls "${libevent_url}" "${tmp_dir}/libevent/libevent.tar.gz"
    std_build 'libevent' "--enable-shared"
  fi

  # build ncurses
  if ! [ -f "${build_dir}/lib/libncurses.a" ]; then
    curls "${ncurses_url}" "${tmp_dir}/ncurses/ncurses.tar.gz" "${ncureses_asc}" \
    'https://invisible-island.net/public/dickey-invisible-island.txt'
    std_build 'ncurses' "--with-shared --with-termlib --enable-pc-files \
                        --with-pkg-config-libdir=${build_dir}/lib/pkgconfig"
  fi

  # build tmux
  echo "Building tmux"
  curls "${tmux_url}" "${tmp_dir}/tmux/tmux.tar.gz"
  ( cd "${tmp_dir}/tmux"   && \
    tar xvf ./tmux.tar.gz  && \
    cd tmux-*/             && \
    LDFLAGS=${build_dir}/lib  \
    ACLOCAL_PATH=${build_dir}/share/aclocal-1.16 \
    ./autogen.sh && \
    #PKG_CONFIG_PATH=${build_dir}/lib/pkgconfig \
    ./configure --enable-static --prefix=${build_dir}  && \
    make && make install)
fi

# Build nvim
if ! [ -f "${build_dir}/bin/nvim" ] ; then
  echo "Building nvim"
  curls "${nvim_url}" "${tmp_dir}/neovim/neovim.tar.gz"
  std_build 'neovim'
fi

# ctags
if ! [ -f "${build_dir}/bin/ctags" ] ; then
  git clone "${ctags_url}" "${tmp_dir}/ctags"
  ( cd "${tmp_dir}" && \
      "./autogen.sh" && \
      "./configure" --prefix="${HOME}" && \
      make && \
      make install )
fi

# cleanup if path is temporary
if [[ ! ${PATH} =~ .*${build_dir}.* ]]; then
  echo rm -rf "${build_dir}"
fi
rm -rf "${tmp_dir}"
