#!/bin/bash
# Script for quickly compiling tools
static="${STATIC:-true}"
download_dir="${DOWNLOAD_DIR:-${HOME}/tmp/artifacts}"
build_dir="${BUILD_DIR:-${HOME}/tmp/usr/local}"
orig_path="${PATH}"

usage() {
  cat <<EOF
Currently installable packages:
rust, ripgrep, tmux, nvim

By default the script will not install deps to system, but will instead install
everything to a temporary directory (default ${HOME}/tmp/usr/local). When
passing in the -i flag all packages will be installed to the system directory
(/usr/local/)

build.sh [-h] [-p rust,ripgrep,tmux,nvim]
  -h              print help message
  -i              short cut key to install to build packages to system
                  directory (/usr/local)
  -p PACKAGE      comma separated list of package to install
  -b BUILD_DIR    build packages to BUILD_DIR directory (${HOME}/tmp/usr/local)
  -d BUILD_DIR    build depenednecies to BUILD_DIR directory (${HOME}/tmp/usr/local)
                  by setting this to a different directory you can cleanup
                  the build tools after
  -r PACKAGE      TODO: remove specified package
EOF
  exit 0
}

while getopts ":hip:b:d:r:" opt; do
  case ${opt} in
    h) usage ;;
    i) build_dir='/usr/local' ;;
    p) build_list=(${OPTARG//,/ }) ;;
    b)
      if [ -d ${OPTARG} ]; then
        build_dir="${OPTARG}"
      else
        echo "no directory ${OPTARG}"
        exit 1
      fi
    ;;
    d)
      if [ -d ${OPTARG} ]; then
        dep_build_dir="${OPTARG}"
      else
        echo "no directory ${OPTARG}"
        exit 1
      fi
    ;;
    r)
      echo "i didn't make it yet"
      exit 0
    ;;
    *)
      echo "No such option: ${opt}"
      usage
    ;;
  esac
done

# Environment Varibales
PATH="${PATH}:${build_dir}/bin"
[ -z "${dep_build_dir}" ] && dep_build_dir="${build_dir}"

# Source build variables
. "${script_dir}/build_env.sh"

# restore PATH on exit
trap "PATH=\"${orig_path}\"" EXIT SIGINT SIGTERM

# Build list: list of packages to bulid
# default is build all
build_list=(rust ripgrep tmux nvim)

# Create build directories if not exist
mkdir -p "${build_dir}"
mkdir -p "${download_dir}"

###############
# Helpers
function std_build {
  local _pkg_name="${1}"
  local _build_dir="${2:-${build_dir}}"
  local _extra_config_flags=(${CONFIG_FLAGS:-})
  local _extra_make_flags=(${MAKE_FLAGS:-})
  local _extra_make_install_flags=(${MAKE_INSTALL_FLAGS:-})

  ( cd "${download_dir}/${_pkg_name}"    && \
    tar xvf ${_pkg_name}.tar.gz          && \
    cd ${_pkg_name}-*/                   && \
    [ -f "./configure" ] && ./configure "--prefix=${_build_dir}" "${_extra_config_flags[@]}" ||\
    make -j4 "${_extra_make_flags}" && make -j4 "${_extra_make_install_flags}" install )
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

build_tools(){
  # build autoconf
  if ! [ -f "${deps_build_dir}/bin/autoconf" ] ; then
    curls "${autoconf_url}" "${download_dir}/autoconf/autoconf.tar.gz"
    std_build 'autoconf' "${deps_build_dir}"
  fi

  # build automake
  if ! [ -f "${deps_build_dir}/bin/aclocal" ] ; then
    curls "${automake_url}" "${download_dir}/automake/automake.tar.gz"
    std_build 'automake' "${deps_build_dir}"
  fi

  # build pkg-config
  if ! [ -f "${deps_build_dir}/bin/pkg-config" ] ; then
    curls "${pkgconfig_url}" "${download_dir}/pkg-config/pkg-config.tar.gz"
    CONFIG_FLAGS='--with-internal-glib' std_build 'pkg-config' "${deps_build_dir}"
  fi

  # build cmake
  if ! [ -f "${deps_build_dir}/bin/cmake" ] ; then
    curls "${cmake_url}" "${download_dir}/cmake/cmake.tar.gz"
    std_build 'cmake' "${deps_build_dir}"
  fi

  # build bison
  # curls "${bison_url}" "${download_dir}/bison/bison.tar.gz"
  # std_build 'bison'
}

install_rust() {
  if ! [ -f "${build_dir}/bin/cargo" ] ; then
    echo "Installing rust"

    # By default rust will install cargo to ${HOME}
    # If not installing rust to system, install rust to temporary directory
    if [[ ! ${build_dir} =~ ^/usr.*  ]]; then
      export CARGO_HOME="${build_dir}/cargo"
      export RUSTUP_HOME="${build_dir}/cargo"
      export PATH="${PATH}:${RUSTUP_HOME}/bin"
    fi

    curl --proto '=https' --tlsv1.2 -sSf "${rust_url}" | bash -s -- -y
    rustup toolchain install nightly --allow-downgrade --profile minimal --component cargo

    # If building in system standard directory, also write cargo home
    if [[ ${build_dir} =~ ^/usr.*  ]]; then
      sed -i \
      '/^\# Environment variables/a PATH=\$PATH:'"${CARGO_HOME}" \
      "${HOME}/.bashrc"
    fi
  fi
}

build_ripgrep(){
  if ! [ -f "${build_dir}/bin/rg" ] ; then
    install_rust

    echo "Building ripgrep"
    [ ! -d "${download_dir}/ripgrep" ] && git clone "${ripgrep_url}" "${download_dir}/ripgrep"
    ( cd "${download_dir}/ripgrep" && \
      cargo build --release   && \
      cp ./target/release/rg "${HOME}/bin" )
  fi
}

build_tmux() {
  if ! [ -f "${build_dir}/bin/tmux" ] ; then

    # build libevent
    if ! [ -f ${build_dir}/lib/libevent.a ]; then
      curls "${libevent_url}" "${download_dir}/libevent/libevent.tar.gz"
      std_build 'libevent' "--enable-shared"
    fi

    # build ncurses
    if ! [ -f "${build_dir}/lib/libncurses.a" ]; then
      curls "${ncurses_url}" "${download_dir}/ncurses/ncurses.tar.gz" "${ncureses_asc}" \
      'https://invisible-island.net/public/dickey-invisible-island.txt'
      std_build 'ncurses' "--with-shared --with-termlib --enable-pc-files \
                          --with-pkg-config-libdir=${build_dir}/lib/pkgconfig"
    fi

    # build tmux
    echo "Building tmux"
    curls "${tmux_url}" "${download_dir}/tmux/tmux.tar.gz"
    ( cd "${download_dir}/tmux"   && \
      tar xvf ./tmux.tar.gz  && \
      cd tmux-*/             && \
      LDFLAGS=${build_dir}/lib  \
      ACLOCAL_PATH=${build_dir}/share/aclocal-1.16 \
      ./autogen.sh && \
      #PKG_CONFIG_PATH=${build_dir}/lib/pkgconfig \
      ./configure --enable-static --prefix=${build_dir}  && \
      make && make install)
  fi
}

build_nvim(){
  if ! [ -f "${build_dir}/bin/nvim" ] ; then
    echo "Building nvim"
    curls "${nvim_url}" "${download_dir}/neovim/neovim.tar.gz"
    MAKE_INSTALL_FLAGS="DESTDIR=${build_dir}" MAKE_FLAGS="CMAKE_INSTALL_PREFIX=${build_dir}" std_build 'neovim'
  fi
}

[[ "${build_list[@]}" =~ "rust" ]] && install_rust
[[ "${build_list[@]}" =~ "ripgrep" ]] && build_ripgrep
[[ "${build_list[@]}" =~ "tmux" ]] && build_tmux
[[ "${build_list[@]}" =~ "nvim" ]] && build_nvim


# ctags
#if ! [ -f "${build_dir}/bin/ctags" ] ; then
#  git clone "${ctags_url}" "${download_dir}/ctags"
#  ( cd "${download_dir}" && \
#      "./autogen.sh" && \
#      "./configure" --prefix="${HOME}" && \
#      make && \
#      make install )
#fi

# cleanup if path is temporary
if [[ ! ${PATH} =~ .*${build_dir}.* ]]; then
  echo rm -rf "${build_dir}"
fi
rm -rf "${download_dir}"

# Install to your machine with rsync
# rsync -a -u ${build_dir} /usr/local
