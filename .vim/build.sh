#!/bin/bash

. "${script_dir}/build_env.sh"
static="${STATIC:-true}"
tmp_dir="${TMP_DIR:-${HOME}/tmp}"
build_dir="${BUILD_DIR:-/usr/local}"
orig_path="${PATH}"
PATH="${PATH}:${build_dir}/bin"

mkdir -p "${build_dir}"

function std_build {
  local _pkg_name="${1}"
  local _prefix="${2}"

  ( cd "${tmp_dir}/${_pkg_name}"  && \
    tar xvf ${_pkg_name}.tar.gz    && \
    cd ${_pkg_name}-*/             && \
    ./configure --prefix=${_prefix} && \
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

# build autoconf
if ! which autoconf >/dev/null; then
  curls "${autoconf_url}" "${tmp_dir}/autoconf/autoconf.tar.gz"
  ( cd "${tmp_dir}/autoconf" && \
    tar xvf autoconf.tar.gz   && \
    cd autoconf-*/            && \
    ./configure --prefix=${build_dir} && \
    make && make install )
fi

# build automake
if ! which aclocal >/dev/null; then
  curls "${automake_url}" "${tmp_dir}/automake/automake.tar.gz"
  ( cd "${tmp_dir}/automake"  && \
    tar xvf automake.tar.gz    && \
    cd automake-*/             && \
    ./configure --prefix=${build_dir} && \
    make && make install )
fi

# build pkg-config
if ! which pkg-config >/dev/null; then
  curls "${pkgconfig_url}" "${tmp_dir}/pkgconfig/pkgconfig.tar.gz"
  ( cd "${tmp_dir}/pkgconfig"  && \
    tar xvf pkgconfig.tar.gz    && \
    cd pkg-config-*/             && \
    ./configure --prefix=${build_dir} && \
    make && make install )
fi

# build bison
# curls "${bison_url}" "${tmp_dir}/bison/bison.tar.gz"
# ( cd "${tmp_dir}/bison"  && \
#   tar xvf bison.tar.gz    && \
#   cd bison-*/             && \
#   ./configure --prefix=${build_dir} && \
#   make && make install )

# build ripgrep
if ! which rg > /dev/null ; then
  if ! which cargo > /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf "${rust_url}" | bash -s -- -y
    sed -i '/^\# Environment variables/a PATH=\$PATH:\$HOME\/.cargo\/bin' \
    "${HOME}/.bashrc"
  fi

  git clone "${ripgrep_url}" "${tmp_dir}/ripgrep"
  ( cd "${tmp_dir}/ripgrep"           && \
    cargo build --release              && \
    cp ./target/release/rg "${HOME}/bin" )
fi

# build tmux
if ! which tmux > /dev/null ; then
  # build libevent
  if [ ! -f ${build_dir}/lib/libevent.a ]; then
    curls "${libevent_url}" "${tmp_dir}/libevent/libevent.tar.gz"
    # Can't find public key
    #  "${libevent_asc}"
    ( cd "${tmp_dir}/libevent"   && \
      tar xvf ./libevent.tar.gz    && \
      cd libevent-*/              && \
      ./configure --prefix=${build_dir} --enable-shared && \
      make && make install )
  fi

  # build ncurses
  if [ ! -f ${build_dir}/lib/libncurses.a ]; then
    curls "${ncurses_url}" "${tmp_dir}/ncurses/ncurses.tar.gz" \
      "${ncureses_asc}" \
      'https://invisible-island.net/public/dickey-invisible-island.txt'
    ( cd "${tmp_dir}/ncurses"  && \
      tar xvf ./ncurses.tar.gz     && \
      cd ncurses-*/               && \
      ./configure --prefix=${build_dir} --with-shared --with-termlib \
      --enable-pc-files --with-pkg-config-libdir=${build_dir}/lib/pkgconfig && \
      make && make install )
  fi

  # build tmux
  if ! which tmux > /dev/null ; then
    curls "${tmux_url}" "${tmp_dir}/tmux/tmux.tar.gz"
    ( cd "${tmp_dir}/tmux"   && \
        tar xvf ./tmux.tar.gz && \
        cd tmux-*/            && \
        LDFLAGS=${build_dir}/lib
        ACLOCAL_PATH=${build_dir}/share/aclocal ./autogen.sh
        PKG_CONFIG_PATH=${build_dir}/lib/pkgconfig \
          ./configure --enable-static --prefix=${build_dir}  && \
        make && make install)
  fi
fi

# ctags
if ! which ctags > /dev/null ; then
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
