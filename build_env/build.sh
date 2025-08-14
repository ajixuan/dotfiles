#!/bin/bash
# Script for quickly compiling tools
set -Eeo pipefail

# Default variables
script_dir="$(dirname ${BASH_SOURCE[0]})"
static="${STATIC:-true}"
build_base_dir="${BUILD_DIR:-${HOME}/local_builds}"
build_list=()
export_path=false
job_count=4

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[m'

usage() {
  cat <<EOF
Currently installable packages:
rust, ripgrep, tmux, nvim, fzf, alacritty

By default the script will not install deps to system, but will instead install
everything to a temporary directory (default ${HOME}/tmp/usr/local). When
passing in the -i flag all packages will be installed to the system directory
(/usr/local/)

build.sh [-h] [-p rust,rigrep,tmux,nvim,fzf,alacritty]
  -h                     print help message
  -i                     update PATH to build_dir/bin
  -p PACKAGE             comma separated list of package to install
  -b BUILD_DIR           build packages to BUILD_DIR directory (${HOME}/tmp/usr/local)
  -d DEPENDENCIES_DIR    build depenednecies to DEPENDENCIES_DIR (${HOME}/tmp/usr/local)
                         setting this to a different directory allows quick cleanup
                         of build dependencies with the -c flag
  -c                     Clean out cached download artifacts
  -t JOB_COUNT           Number of concurrent jobs to spawn, default 4
  -r PACKAGE             TODO: remove specified package
EOF
  exit 0
}

while getopts ":hip:b:d:r:c:t:" opt; do
  case ${opt} in
    h) usage ;;
    i) export_path=true ;;
    p) build_list=(${OPTARG//,/ }) ;;
    t) job_count="${OPTARG}"       ;;
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

# Prereq packages
if ! which make &> /dev/null; then
  printf "${RED} error: make not found\n"
  exit 1
fi


# Set some traps
catch() {
  printf "${RED} error $1 occurred on $2 in $3\n"
}
trap 'catch $? $LINENO ${FUNCNAME[0]}' ERR

# Environment Varibales
download_dir="${DOWNLOAD_DIR:-${build_base_dir}/tmp/artifacts}"
build_dir="${build_base_dir}/usr/local"
orig_path="${PATH}"
export PATH="${PATH}:/usr/bin:${build_dir}/bin"

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
else
  export CARGO_HOME="${HOME}/.cargo"
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
#
function untar {
  local _pkg_name="${1}"
  local _build_dir="${2:-${build_dir}}"

  if [ ! -d "${download_dir}/${_pkg_name}" ] ; then
    set +o pipefail
    tar xvf "${download_dir}/tars/${_pkg_name}.tar.gz" -C "${download_dir}"

    # Rename the directory in the tar, doing it this way because tar
    # --strip-components 1 is only supported on GNU and BSD tars
    _extract_dir="$(tar tvf "${download_dir}/tars/${_pkg_name}.tar.gz" | head -n1 | awk '{print $NF}' | cut -d '/' -f1)"
    mv "${download_dir}/${_extract_dir}" "${download_dir}/${_pkg_name}" # rename the untarred directory name
    set -o pipefail
  fi
}

function cmake_build {
  local _pkg_name="${1}"
  local _build_dir="${2:-${build_dir}}"
  local _extra_config_flags=(${CONFIG_FLAGS:-})
  local _extra_make_flags=(${MAKE_FLAGS:-})
  local _extra_make_install_flags=(${MAKE_INSTALL_FLAGS:-})

  untar "${_pkg_name}" "${_build_dir}"

  pushd .
  cd "${download_dir}/${_pkg_name}"
  cmake  "${_extra_config_flags[@]}" -DCMAKE_INSTALL_PREFIX=${_build_dir} ./
  make -j${job_count} "${_extra_make_install_flags[@]}" install
  unset CONFIG_FLAGS MAKE_FLAGS MAKE_INSTALL_FLAGS
  popd
}

function std_build {
  local _pkg_name="${1}"
  local _build_dir="${2:-${build_dir}}"
  local _extra_config_flags=(${CONFIG_FLAGS:-})
  local _extra_make_flags=(${MAKE_FLAGS:-})
  local _extra_make_install_flags=(${MAKE_INSTALL_FLAGS:-})
  local _install_command=${INSTALL_COMMAND:-install}

  untar "${_pkg_name}" "${_build_dir}"

  pushd .
  cd "${download_dir}/${_pkg_name}"
  [ -f "./configure" ] && \
    ./configure "--prefix=${_build_dir}" "${_extra_config_flags[@]}"
  [ -f "./autogen.sh" ] && \
    ./autogen.sh "--prefix=${_build_dir}" "${_extra_config_flags[@]}"
  pwd
  ls Makefile
  make -j${job_count} "${_extra_make_flags[@]}"
  make -j${job_count} "${_extra_make_install_flags[@]}" install
  unset CONFIG_FLAGS MAKE_FLAGS MAKE_INSTALL_FLAGS
  popd
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

  # build autoconf
  if ! [ -f "${deps_build_dir}/bin/autoconf" ] ; then
    printf "${GREEN}building autoconf${NC}\n"
    curls "${autoconf_url}" "autoconf.tar.gz"
    std_build 'autoconf' "${deps_build_dir}"
  fi

  # build automake
  if ! [ -f "${deps_build_dir}/bin/aclocal" ] ; then
    printf "${GREEN}building automake${NC}\n"
    curls "${automake_url}" "automake.tar.gz"
    std_build 'automake' "${deps_build_dir}"
  fi

  # build pkg-config
  if ! [ -f "${deps_build_dir}/bin/pkg-config" ] ; then
    printf "${GREEN}building pkg-config${NC}\n"
    curls "${pkgconfig_url}" "pkg-config.tar.gz"
    CONFIG_FLAGS='--with-internal-glib' std_build 'pkg-config' "${deps_build_dir}"
  fi

  # build cmake
  if ! [ -f "${deps_build_dir}/bin/cmake" ] ; then
    printf "${GREEN}building cmake${NC}\n"
    curls "${cmake_url}" "cmake.tar.gz"
    std_build 'cmake' "${deps_build_dir}"
  fi

  # build libtool
  if ! [ -f "${deps_build_dir}/bin/libtool" ] ; then
    printf "${GREEN}building libtool${NC}\n"
    curls "${libtool_url}" "libtool.tar.gz"
    std_build 'libtool' "${deps_build_dir}"
  fi

  # build m4
  # I give up trying to build m4
  #if ! [ -f "${deps_build_dir}/bin/m4" ] ; then
  #  curls "${m4_url}" "m4.tar.gz"
  #  std_build 'm4' "${deps_build_dir}"
  #fi

  # build gettext
  if ! [ -f "${build_dir}/bin/gettextize" ] ; then
    printf "${GREEN}building gettext${NC}\n"
    curls "${gettext_url}" "gettext.tar.gz"
    std_build 'gettext' "${deps_build_dir}"
  fi

  # build bison
  if ! [ -f "${deps_build_dir}/bin/yacc" ] ; then
    printf "${GREEN}building bison${NC}\n"
    curls "${bison_url}" "bison.tar.gz"
    std_build 'bison' "${deps_build_dir}"
  fi

  # build unzip
  if ! [ -f "${build_dir}/bin/unzip" ] ; then
    printf "${GREEN}Building unzip${NC}\n"
    git_cl "${unzip_url}" "${download_dir}/unzip"
    cmake_build 'unzip' "${deps_build_dir}"
  fi

  # build freetype
  if ! [ -f "${build_dir}/lib/libfreetype.so" ]; then
    printf "${GREEN}Building freetype2${NC}\n"
    curls "${freetype_url}" "freetype.tar.gz"
    std_build 'freetype' "${deps_build_dir}"
  fi

  if ! ls ${build_dir}/lib/libexpat.so* ; then
    printf "${GREEN}Building expat${NC}\n"
    curls "${expat_url}" "expat.tar.gz"
    cmake_build 'expat' "${deps_build_dir}"
  fi

  if ! [ -f "${build_dir}/bin/gperf" ]; then
    printf "${GREEN}Building gperf${NC}\n"
    curls "${gperf_url}" "gperf.tar.gz"
    std_build 'gperf' "${deps_build_dir}"
  fi

  if ! [ -d "${build_dir}/share/fontconfig" ]; then
    printf "${GREEN}Building fontconfig${NC}\n"
    curls "${fontconfig_url}" "fontconfig.tar.gz"
    std_build 'fontconfig' "${deps_build_dir}"
  fi
}

install_rust() {
  if ! "${build_dir}/cargo/bin/rustc" -V ; then
    printf "${GREEN}Installing rust${NC}\n"
    curl --proto '=https' --tlsv1.2 -sSf "${rust_url}" | bash -s -- -y
    source "${CARGO_HOME}/env"
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

    printf "${GREEN}Building ripgrep${NC}\n"
    ! [ -d "${download_dir}/ripgrep" ] && git clone "${ripgrep_url}" "${download_dir}/ripgrep"
    ( cd "${download_dir}/ripgrep" && \
      cargo build --release && \
      cp ./target/release/rg "${build_dir}/bin/" )
  fi
}


install_fzf() {
  if ! [ -f "${build_dir}/bin/fzf" ] ; then
    printf "${GREEN}Installing fzf to ${HOME}/.fzf${NC}\n"
    git_cl "${fzf_url}" "${HOME}/.fzf"
    ( cd ${HOME}/.fzf && ./install --all )
  fi
}

build_tmux() {
  if ! [ -f "${build_dir}/bin/tmux" ] ; then

    # build libevent
    if ! [ -f ${deps_build_dir}/lib/libevent.a ]; then
      printf "${GREEN}Building libevent${NC}\n"
      curls "${libevent_url}" "libevent.tar.gz"
      CONFIG_FLAGS="--enable-shared" cmake_build 'libevent' "${deps_build_dir}"
    fi

    # build ncurses
    if ! [ -f "${deps_build_dir}/lib/libncurses.a" ]; then
      printf "${GREEN}Building ncurses${NC}\n"
      curls "${ncurses_url}" "ncurses.tar.gz" "${ncureses_asc}" \
      'https://invisible-island.net/public/dickey-invisible-island.txt'
      CONFIG_FLAGS="--with-shared     \
                    --with-termlib    \
                    --enable-pc-files \
                    --with-pkg-config-libdir=${deps_build_dir}/lib/pkgconfig" \
      std_build 'ncurses' "${deps_build_dir}"
    fi

    # build tmux
    printf "${GREEN}Building tmux${NC}\n"
    #curls "${tmux_url}" "tmux.tar.gz"
    # Note on building tmux:
    # - Since deps_build_dir could be set in a non standard directory, this var
    #   is set to where *.pc files are found. they can usually be found in the
    #   /lib directory
    # - when the dependencies are built above, make sure their pkgconfig manifest
    #   files (*.pc files) have the correct prefix in them. Otherwise setting
    #   PKG_CONFIG_PATH won't be able to find the correct header files
    git_cl "${tmux_url}" "${download_dir}/tmux"
    ( cd "${download_dir}/tmux"   && \
      LDFLAGS=${deps_build_dir}/lib  \
      ACLOCAL_PATH=${deps_build_dir}/share/aclocal-1.16 \
      ./autogen.sh && \
      PKG_CONFIG_PATH=${deps_build_dir}/lib/pkgconfig \
      ./configure --enable-static --prefix=${build_dir}  && \
      make && make install)
  fi
}

build_nvim(){
  if ! [ -f "${build_dir}/bin/nvim" ] ; then
    printf "${GREEN}Building nvim${NC}\n"
    git_cl "${nvim_url}" "${download_dir}/neovim"
    MAKE_FLAGS="USE_BUNDLED_LUV=OFF CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS=\"-DCMAKE_INSTALL_PREFIX=${build_base_dir}/usr/local/\"" \
    std_build 'neovim'
  fi
}

build_alacritty(){
  # dependencies
  install_rust

  if ! [ -f "${build_dir}/bin/alacritty" ] ; then
    printf "${GREEN}Building alacritty${NC}\n"

    curls "${alacritty_url}" "alacritty.tar.gz"
    untar "alacritty"
    ( cd "${download_dir}/alacritty" &&
      cargo build --release &&
      [ ! -f ./target/release/alacritty ] && printf "${RED}Error: alacritty failed to build" && exit 1 ||
      mv './target/release/alacritty' "${build_dir}/bin/" )
  fi
}
if [ ${#build_list[*]} -eq 0 ]; then
  printf "${RED}No tools specified, please use -p and choose a tool to build\n"
  usage
  exit 0
fi

[[ "${build_list[@]}" =~ fzf ]]  && install_fzf
[[ "${build_list[@]}" =~ rust ]] && install_rust
if [[ "${build_list[@]}" =~ ripgrep|tmux|nvim|alacritty ]]; then
  build_tools
  [[ "${build_list[@]}" =~ ripgrep ]] && build_ripgrep
  [[ "${build_list[@]}" =~ tmux ]] && build_tmux
  [[ "${build_list[@]}" =~ nvim ]] && build_nvim
  [[ "${build_list[@]}" =~ alacritty ]] && build_alacritty
fi

if ${export_path} ; then
  path_string='PATH=${PATH}:'"${build_dir}/bin"
  rustup_home_path="RUSTUP_HOME=${build_dir}/usr/local/cargo"
  cargo_home_path="CARGO_HOME=${build_dir}/usr/local/cargo"
  grep -qxF "${path_string}" "${HOME}/.bashrc" || echo ${path_string} >> "${HOME}/.bashrc"
  grep -qxF "${cargo_home_path}" "${HOME}/.bashrc" || echo ${cargo_home_path} >> "${HOME}/.bashrc"
  grep -qxF "${rustup_home_path}" "${HOME}/.bashrc" || echo ${rustup_home_path} >> "${HOME}/.bashrc"
fi
