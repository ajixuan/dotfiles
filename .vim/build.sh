#!/bin/bash

. "${script_dir}/build_env.sh"
static="${STATIC:-true}"
tmp_dir="${TMP_DIR:-${HOME}/tmp}"
build_dir="${BUILD_DIR:-/usr/local}"
orig_path="${PATH}"
PATH="${PATH}:${build_dir}/bin"

mkdir -p "${build_dir}"

###############
# Helpers
function std_build {
  local _pkg_name="${1}"
  local _extra_config_flags=(${2:-})

  ( cd "${tmp_dir}/${_pkg_name}"  && \
    tar xvf ${_pkg_name}.tar.gz    && \
    cd ${_pkg_name}-*/             && \
    ./configure --prefix=${build_dir} ${_extra_config_flags[@]} && \
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

  echo "downloading ${_url}"
  curl -LsSf "${_url}" --create-dirs -o "${_output}"
  if [ -n "${_asf_url}" ]; then
    echo "verifying with key from ${_asf_url}"
    curl -LsSf "${_asf_url}" --create-dirs -o "${_output}.asf"
    gpg --verify "${_output}.asf"
  fi
}

##########################
# Build deps

if ${build_deps}; then
  # build autoconf
  if ! which autoconf >/dev/null; then
    curls "${autoconf_url}" "${tmp_dir}/autoconf/autoconf.tar.gz"
    std_build 'autoconf'
  fi

  # build automake
  if ! which aclocal 2>&1 >/dev/null; then
    curls "${automake_url}" "${tmp_dir}/automake/automake.tar.gz"
    std_build 'automake'
  fi

  # build pkg-config
  if ! which pkg-config 2>&1 >/dev/null; then
    curls "${pkgconfig_url}" "${tmp_dir}/pkg-config/pkg-config.tar.gz"
    std_build 'pkg-config'
  fi

  # build bison
  # curls "${bison_url}" "${tmp_dir}/bison/bison.tar.gz"
  # std_build 'bison'
fi

# build ripgrep
if ! which rg 2>&1 > /dev/null ; then
  if ! which cargo > /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf "${rust_url}" | bash -s -- -y
    sed -i '/^\# Environment variables/a PATH=\$PATH:\$HOME\/.cargo\/bin' "${HOME}/.bashrc"
  fi

  git clone "${ripgrep_url}" "${tmp_dir}/ripgrep"
  ( cd "${tmp_dir}/ripgrep"           && \
    cargo build --release              && \
    cp ./target/release/rg "${HOME}/bin" )
fi

# build tmux
if ! which tmux 2>&1 > /dev/null ; then
  # build libevent
  if [ ! -f ${build_dir}/lib/libevent.a ]; then
    curls "${libevent_url}" "${tmp_dir}/libevent/libevent.tar.gz"
    std_build 'libevent' "--enable-shared"
  fi

  # build ncurses
  if [ ! -f ${build_dir}/lib/libncurses.a ]; then
    curls "${ncurses_url}" "${tmp_dir}/ncurses/ncurses.tar.gz" \
      "${ncureses_asc}" \
      'https://invisible-island.net/public/dickey-invisible-island.txt'
      std_build 'ncurses' \
        "--with-shared --with-termlib --enable-pc-files \
         --with-pkg-config-libdir=${build_dir}/lib/pkgconfig"
  fi

  # build tmux
  if ! which tmux > /dev/null ; then
    curls "${tmux_url}" "${tmp_dir}/tmux/tmux.tar.gz"
    ( cd "${tmp_dir}/tmux"   && \
        tar xvf ./tmux.tar.gz && \
        cd tmux-*/            && \
        LDFLAGS=${build_dir}/lib \
        ACLOCAL_PATH=${build_dir}/share/aclocal-1.16 \
        ./autogen.sh && \
        PKG_CONFIG_PATH=${build_dir}/lib/pkgconfig \
        ./configure --enable-static --prefix=${build_dir}  && \
        make && make install)
  fi
fi

# ctags
if ! which ctags 2>&1 > /dev/null ; then
  git clone "${ctags_url}" "${tmp_dir}/ctags"
  ( cd "${tmp_dir}" && \
      "./autogen.sh" && \
      "./configure" --prefix="${HOME}" && \
      make && \
      make install )
fi

# cleanup
PATH="${orig_path}"
if [[ ! ${PATH} =~ .*${build_dir}.* ]]; then
  echo rm -rf "${build_dir}"
fi
rm -rf "${tmp_dir}"
