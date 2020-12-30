#!/bin/bash
# Script for quickly compiling tools
set -e

# Default variables
script_dir="$(dirname ${BASH_SOURCE[0]})"
static="${STATIC:-true}"
build_base_dir="${BUILD_DIR:-${HOME}/local_builds}"
build_list=(rust ripgrep tmux nvim)

usage() {
  cat <<EOF
Currently installable packages:
rust, ripgrep, tmux, nvim, fzf

By default the script will not install deps to system, but will instead install
everything to a temporary directory (default ${HOME}/tmp/usr/local). When
passing in the -i flag all packages will be installed to the system directory
(/usr/local/)

build.sh [-h] [-p rust,ripgrep,tmux,nvim,fzf]
  -h              print help message
  -i              short cut key to install to build packages to system
                  directory (/usr/local)
  -p PACKAGE      comma separated list of package to install
  -b BUILD_DIR    build packages to BUILD_DIR directory (${HOME}/tmp/usr/local)
  -d BUILD_DIR    build depenednecies to BUILD_DIR directory (${HOME}/tmp/usr/local)
                  by setting this to a different directory you can cleanup
                  the build tools after
  -c              Clean out cached download artifacts
  -r PACKAGE      TODO: remove specified package
EOF
  exit 0
}

while getopts ":hip:b:d:r:c" opt; do
  case ${opt} in
    h) usage ;;
    i) build_base_dir='' ;;
    p) build_list=(${OPTARG//,/ }) ;;
    b)
      echo "setting build_dir to ${OPTARG}"
      build_base_dir="${OPTARG}"
    ;;
    d)
      if [ -d ${OPTARG} ]; then
        echo "setting deps_build_dir to ${OPTARG}"
        deps_build_dir="${OPTARG}"
      else
        echo "no directory ${OPTARG}"
        exit 1
      fi
    ;;
    r)
      echo "i didn't make it yet"
      exit 0
    ;;
    c)
      clear_cache=true
    ;;
    *)
      echo "No such option: ${opt}"
      usage
    ;;
  esac
done

# Environment Varibales
download_dir="${DOWNLOAD_DIR:-${build_base_dir}/tmp/artifacts}"
build_dir="${build_base_dir}/usr/local"
orig_path="${PATH}"
export PATH="/usr/bin:${build_dir}/bin"

# Put build_dir and deps_build_dir onto path
if [ -z "${deps_build_dir}" ]; then
  deps_build_dir="${build_dir}"
else
  export PATH="${PATH}:${deps_build_dir}/bin"
fi

# By default rust will install cargo to ${HOME}
# If not installing rust to system, install rust to temporary directory
if [[ ! ${build_dir} =~ ^/usr.*  ]]; then
  export CARGO_HOME="${build_dir}/cargo"
  export RUSTUP_HOME="${build_dir}/cargo"
  export PATH="${PATH}:${RUSTUP_HOME}/bin"
fi

# Source build variables
. "${script_dir}/build_env.sh"

# restore PATH on exit
trap "PATH=\"${orig_path}\"" EXIT SIGINT SIGTERM

# Clean cache
${clear_cache:-false} && rm -rf ${download_dir}

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

  if [ ! -d "${download_dir}/${_pkg_name}"* ] ; then
    tar xvf "${download_dir}/tars/${_pkg_name}.tar.gz" -C "${download_dir}"

    # Rename the directory in the tar, doing it this way because tar
    # --strip-components 1 is only supported on GNU and BSD tars
    _extract_dir="$(tar tvf "${download_dir}/tars/${_pkg_name}.tar.gz" | head -n1 | awk '{print $NF}' | cut -d "/" -f1)"
    mv "${download_dir}/${_extract_dir}" "${download_dir}/${_pkg_name}" # rename the untarred directory name
  fi

  ( cd "${download_dir}/${_pkg_name}" && \
    [ -f "./configure" ] && \
    ./configure "--prefix=${_build_dir}" "${_extra_config_flags[@]}" || \
    make -j4 "${_extra_make_flags[@]}" && \
    make -j4 "${_extra_make_install_flags[@]}" install )
  unset CONFIG_FLAGS MAKE_FLAGS MAKE_INSTALL_FLAGS
}

# Curl and verify
function curls {
  local _url="${1}"
  local _output="${2}"
  local _asf_url="${3:-}"
  local _import_key_url="${4:-}"

  [ ! -d "${download_dir}/tars" ] && mkdir -p "${download_dir}/tars"

  if [ -n "${_import_key_url}" ]; then
    echo "importing key from ${_import_key_url}"
    curl -LsSf "${_import_key_url}" -o /tmp/tmp.key
    gpg --import /tmp/tmp.key
    rm /tmp/tmp.key
  fi

  if ! [ -f "${download_dir}/tars/${_output}" ]; then
    echo "downloading ${_url}"
    curl -LsSf "${_url}" --create-dirs -o "${download_dir}/tars/${_output}"
    if [ -n "${_asf_url}" ]; then
      echo "verifying with key from ${_asf_url}"
      curl -LsSf "${_asf_url}" --create-dirs -o "${_output}.asf"
      gpg --verify "${_output}.asf"
    fi
  fi
}

# Git checkout
function git_cl {
  local _url="${1}"
  local _output="${2}"
  [ -d "${_output}" ] && \
  ( cd "${_output}" ; git pull ) || git clone "${_url}" "${_output}"
}

build_tools(){
  # build m4
  #if ! [ -f "${deps_build_dir}/bin/m4" ] ; then
  #  # Cannot clone from git because building m4 from git src requires autconf,
  #  # while building autoconf requires m4
  #  #git_cl "${m4_url}" "${download_dir}/m4"
  #  #( cd ${download_dir}/m4/ && git checkout -b branch-1.4 origin/branch-1.4 )
  #  curls "${m4_url}" "m4.tar.gz"
  #  std_build 'm4' "${deps_build_dir}"
  #fi

  # build autoconf
  if ! [ -f "${deps_build_dir}/bin/autoconf" ] ; then
    curls "${autoconf_url}" "autoconf.tar.gz"
    std_build 'autoconf' "${deps_build_dir}"
  fi

  # build automake
  if ! [ -f "${deps_build_dir}/bin/aclocal" ] ; then
    curls "${automake_url}" "automake.tar.gz"
    std_build 'automake' "${deps_build_dir}"
  fi

  # build pkg-config
  if ! [ -f "${deps_build_dir}/bin/pkg-config" ] ; then
    curls "${pkgconfig_url}" "pkg-config.tar.gz"
    CONFIG_FLAGS='--with-internal-glib' std_build 'pkg-config' "${deps_build_dir}"
  fi

  # build cmake
  if ! [ -f "${deps_build_dir}/bin/cmake" ] ; then
    curls "${cmake_url}" "cmake.tar.gz"
    std_build 'cmake' "${deps_build_dir}"
  fi

  # build libtool
  if ! [ -f "${deps_build_dir}/bin/libtool" ] ; then
    curls "${libtool_url}" "libtool.tar.gz"
    std_build 'libtool' "${deps_build_dir}"
  fi

  # build bison
  if ! [ -f "${deps_build_dir}/bin/yacc" ] ; then
    curls "${bison_url}" "bison.tar.gz"
    std_build 'bison' "${deps_build_dir}"
  fi
}

install_rust() {
  if ! [ -f "${build_dir}/cargo/bin/cargo" ] ; then
    echo "Installing rust"
    curl --proto '=https' --tlsv1.2 -sSf "${rust_url}" | bash -s -- -y
    source "$HOME/.cargo/env"
    rustup toolchain install nightly --allow-downgrade --profile minimal --component cargo

    # If building in system standard directory, also write cargo home
    if [[ ${build_dir} =~ ^/usr.*  ]]; then
      sed -i \
      '/^\# Environment variables/a PATH=\$PATH:'"${CARGO_HOME}" \
      "${HOME}/.bashrc"
    fi
  fi
}

build_ripgrep() {
  if ! [ -f "${build_dir}/bin/rg" ] ; then
    install_rust

    echo "Building ripgrep"
    ! [ -d "${download_dir}/ripgrep" ] && git clone "${ripgrep_url}" "${download_dir}/ripgrep"
    ( cd "${download_dir}/ripgrep" && \
      cargo build --release && \
      cp ./target/release/rg "${build_dir}/bin/" )
  fi
}


install_fzf() {
  if ! [ -f "${build_dir}/bin/fzf" ] ; then
    echo "Installing fzf to ${HOME}/.fzf"
    git_cl "${fzf_url}" "${HOME}/.fzf"
    ( cd ${HOME}/.fzf && ./install --all )
  fi
}

build_tmux() {
  if ! [ -f "${build_dir}/bin/tmux" ] ; then

    # build libevent
    if ! [ -f ${build_dir}/lib/libevent.a ]; then
      curls "${libevent_url}" "libevent.tar.gz"
      CONFIG_FLAGS="--enable-shared" std_build 'libevent' "${deps_build_dir}"
    fi

    # build ncurses
    if ! [ -f "${build_dir}/lib/libncurses.a" ]; then
      curls "${ncurses_url}" "ncurses.tar.gz" "${ncureses_asc}" \
      'https://invisible-island.net/public/dickey-invisible-island.txt'
      CONFIG_FLAGS="--with-shared     \
                    --with-termlib    \
                    --enable-pc-files \
                    --with-pkg-config-libdir=${deps_build_dir}/lib/pkgconfig" \
      std_build 'ncurses' "${deps_build_dir}"
    fi

    # build tmux
    echo "Building tmux"
    #curls "${tmux_url}" "tmux.tar.gz"
    git_cl "${tmux_url}" "${download_dir}/tmux"
    ( cd "${download_dir}/tmux"   && \
      LDFLAGS=${deps_build_dir}/lib  \
      ACLOCAL_PATH=${deps_build_dir}/share/aclocal-1.16 \
      ./autogen.sh && \
      PKG_CONFIG=${deps_build_dir}/bin/pkg-config \
      ./configure --enable-static --prefix=${build_dir}  && \
      make && make install)
  fi
}

build_nvim(){
  if ! [ -f "${build_dir}/bin/nvim" ] ; then
    if ! [ -f "${build_dir}/bin/gettextize" ] ; then
      echo "Building nvim dependency: gettext"
      curls "${gettext_url}" "gettext.tar.gz"
      std_build 'gettext' "${deps_build_dir}"
    fi

    echo "Building nvim"
    #curls "${nvim_url}" "neovim.tar.gz"
    git_cl "${nvim_url}" "${download_dir}/neovim"
    MAKE_FLAGS="CMAKE_BUILD_TYPE=\"Release\" CMAKE_INSTALL_PREFIX=\"${build_base_dir}/usr/local\"" \
    std_build 'neovim'
  fi
}

[[ "${build_list[@]}" =~ fzf ]]  && install_fzf
[[ "${build_list[@]}" =~ rust ]] && install_rust
if [[ "${build_list[@]}" =~ ripgrep|tmux|nvim ]]; then
  build_tools
  [[ "${build_list[@]}" =~ ripgrep ]] && build_ripgrep
  [[ "${build_list[@]}" =~ tmux ]] && build_tmux
  [[ "${build_list[@]}" =~ nvim ]] && build_nvim
fi

