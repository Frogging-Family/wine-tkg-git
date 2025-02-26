#!/bin/bash

# ===========================================================================================================================================================================
# non-makepkg-build.sh - A non-makepkg build script for wine-tkg-git
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#     Created by: Tk-Glitch <ti3nou at gmail dot com>
#     Updated by: loopyd <nightwintertooth at gmail dot com>
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
# This script replaces the wine-tkg PKGBUILD's function for use outside of makepkg or on non-pacman distros
#
# For command-line help, run this script with the `-h|--help` argument :
#
# ./non-makepkg-build.sh -h
#
# You can check for missing dependencies by running this script with either `-d|--deps64` argument for 64-bit dependencies or `e|--deps32` argument for 32-bit dependencies :
#
# ./non-makepkg-build.sh --deps64
# ./non-makepkg-build.sh --deps32
#
# If you want to specify a custom config file, you can use the `--config` argument :
#
# ./non-makepkg-build.sh --config /path/to/your/config/file
#
# On a stock Ubuntu 19.04 install, you'll need the following deps as bare minimum to build default wine-tkg (without Faudio/winevulkan):
#
#   pkg-config (or pkgconf) bison flex schedtool libfreetype6-dev xserver-xorg-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
#
# For 32-bit support : gcc-multilib g++-multilib libfreetype6-dev:i386 xserver-xorg-dev:i386 libgstreamer1.0-dev:i386 libgstreamer-plugins-base1.0-dev:i386
#
# For proton-tkg, the 32-bit dependencies above are required as well as the following additions:
#
#   curl fontforge fonttools libsdl2-dev python3-tk
#
# !!! _sdl_joy_support="true" (default setting) would require libsdl2-dev:i386 but due to a conflict between libsdl2-dev:i386 and libmirclientcpp-dev 
#     (at least on 19.04) you're kinda frogged and should set _sdl_joy_support to "false" to build successfully. You'll lose SDL2 support on 32-bit apps !!!
#
# You're on your own to resolve additional dependencies you might want to build with, such as Faudio.
#
# ===========================================================================================================================================================================

pkgname=wine-tkg
_build_in_tmpfs="true"
_esyncsrcdir='esync'
_where="$PWD" # Track the base directory as different Arch-based distros are moving srcdir around

# Source common functions
source "$_where"/wine-tkg-scripts/prepare.sh
source "$_where"/wine-tkg-scripts/build.sh

srcdir=""

_DEPSHELPER=${_DEPSHELPER:-0}
ACTION="build"

# Print a basic message (included for compatibility with makepkg)
msg() {
  echo -e " \033[1;34m->\033[1;0m $1" >&2
}

# Print a message with a prefix (included for compatibility with makepkg)
msg2() {
  echo -e " \033[1;34m=>\033[1;0m \033[1;1m$1\033[1;0m" >&2
}

# Print a warning message (included for compatibility with makepkg)
warning() {
  echo -e " \033[1;33m==> WARNING: $1\033[1;0m" >&2
}

# Print an error message (included for compatibility with makepkg)
error() {
  echo -e " \033[1;31m===> ERROR: $1\033[1;0m" >&2
}

pkgver() {
  if [ -d "${srcdir}/${_winesrcdir}" ]; then
    if [ "$_use_staging" = "true" ] && [ -d "${srcdir}/${_stgsrcdir}" ] && [[ "$_custom_wine_source" != *"ValveSoftware"* ]]; then
      cd "${srcdir}/${_stgsrcdir}"
    else
      cd "${srcdir}/${_winesrcdir}"
    fi
    _describe_wine      # Retrieve current Wine version - if staging is enabled, staging version will be used instead.
  fi
}

_src_init() {
  # Wine source
  if [ "$_github_mirrorsrc" = "true" ]; then
    _winesrcdir="wine-mirror-git"
    _stgsrcdir="wine-staging-mirror-git"
    _winesrctarget="https://github.com/wine-mirror/wine.git"
    _stgsrctarget="https://github.com/wine-staging/wine-staging.git"
  else
    _winesrcdir="wine-git"
    _stgsrcdir="wine-staging-git"
    _winesrctarget="https://gitlab.winehq.org/wine/wine.git"
    _stgsrctarget="https://gitlab.winehq.org/wine/wine-staging.git"
  fi

  if [ -n "$_custom_wine_source" ]; then
    _winesrcdir=$(sed 's|/|-|g' <<<$(sed 's|.*://.[^/]*/||g' <<<${_custom_wine_source//./}))
    _winesrctarget="$_custom_wine_source"
  fi

  if [ "$_NUKR" != "debug" ]; then
    # Performing the following:
    #
    #   - copy .conf files inside the PKGBUILD's dir to preserve makepkg sourcing and md5sum checking
    #   - copy userpatches inside the PKGBUILD's dir
    find "$_where"/wine-tkg-patches -type f '(' -iname '*.conf' ')' -not -path "*hotfixes*" -exec cp -n {} "$_where" \;
    find "$_where"/wine-tkg-userpatches -type f -name "*.my*" -exec cp -n {} "$_where" \;

    ## Handle git repos similarly to makepkg to preserve repositories when building both with and without makepkg on Arch
    # Wine source
    cd "$_where"
    git clone --mirror "${_winesrctarget}" "$_winesrcdir" 2>"$_where"/prepare.log || true

    # Wine staging source
    git clone --mirror "${_stgsrctarget}" "$_stgsrcdir" 2>>"$_where"/prepare.log || true

    pushd "$srcdir" &>/dev/null

    # Wine staging update and checkout
    cd "$_where"/"${_stgsrcdir}"
    if [[ "${_stgsrctarget}" != "$(git config --get remote.origin.url)" ]]; then
      echo "${_stgsrcdir} is not a clone of $(git config --get remote.origin.url) (\"${_stgsrctarget}\"). Let's nuke stuff to get back on track, hopefully." >>"$_where"/prepare.log
      rm -rf "$_where/${_stgsrcdir}" && rm -rf "${srcdir}/${_stgsrcdir}"
      warning "Your ${_stgsrcdir} clone was deleted due to remote mismatch (\"${_stgsrctarget}\" differs from \"$(git config --get remote.origin.url)\"). Let's try again with a fresh clone."
      _src_init
    fi
    git fetch --all -p
    rm -rf "${srcdir}/${_stgsrcdir}" && git clone "$_where"/"${_stgsrcdir}" "${srcdir}/${_stgsrcdir}"
    cd "${srcdir}"/"${_stgsrcdir}"
    git -c advice.detachedHead=false checkout --force --no-track -B makepkg origin/HEAD
    if [ -n "$_staging_version" ] && [ "$_use_staging" = "true" ]; then
      git -c advice.detachedHead=false checkout "${_staging_version}" 2>>"$_where"/prepare.log
    fi

    # Wine update and checkout
    cd "$_where"/"${_winesrcdir}"
    if [[ "${_winesrctarget}" != "$(git config --get remote.origin.url)" ]]; then
      echo "${_winesrcdir} is not a clone of $(git config --get remote.origin.url) (\"${_winesrctarget}\"). Let's nuke stuff to get back on track, hopefully." >>"$_where"/prepare.log
      rm -rf "$_where/${_winesrcdir}" && rm -rf "${srcdir}/${_winesrcdir}"
      warning "Your ${_winesrcdir} clone was deleted due to remote mismatch (\"${_winesrctarget}\" differs from \"$(git config --get remote.origin.url)\"). Let's try again with a fresh clone."
      _src_init
    fi
    git fetch --all -p
    rm -rf "${srcdir}/${_winesrcdir}" && git clone "$_where"/"${_winesrcdir}" "${srcdir}/${_winesrcdir}"
    cd "${srcdir}"/"${_winesrcdir}"
    git -c advice.detachedHead=false checkout --force --no-track -B makepkg origin/HEAD
    if [ -n "$_plain_version" ] && [ "$_use_staging" != "true" ] || [[ "$_custom_wine_source" = *"ValveSoftware"* ]]; then
      git -c advice.detachedHead=false checkout "${_plain_version}" 2>>"$_where"/prepare.log
      if [ "$_LOCAL_PRESET" = "valve-exp-bleeding" ]; then
        if [ -z "$_bleeding_tag" ]; then
          _bleeding_tag=$(git tag -l --sort=-v:refname | grep "bleeding" | head -n 1)
        fi
        echo -e "Bleeding edge tag: ${_bleeding_tag}" >>"$_where"/prepare.log
        _bleeding_commit=$(git rev-list -n 1 "${_bleeding_tag}")
        echo -e "Bleeding edge commit: ${_bleeding_commit}\n" >>"$_where"/prepare.log
        git -c advice.detachedHead=false checkout "${_bleeding_tag}"
      fi
    fi
    popd &>/dev/null
  fi

  # makepkg proton pkgver loop hack
  if [ "$_ispkgbuild" = "true" ] && [ "$_isfirstloop" = "true" ]; then
    echo "_tmp_ver=\"$(pkgver)\"" >>"$_where"/../proton-tkg/src/proton_tkg_tmp
    exit 0
  fi
}

_script_init() {
  msg2 "Non-makepkg build script will be used.\n"
  _init

  # Set the srcdir, Arch Linux style
  if [ "$_build_in_tmpfs" = "true" ]; then
    rm -rf "$_where"/src
    mkdir -p /tmp/wine-tkg/src
    ln -s /tmp/wine-tkg/src "$_where"
  else
    mkdir -p "$_where"/src
  fi
  srcdir="$_where"/src

  # dependencies
  if [[ "$_nomakepkg_dependency_autoresolver" == "true" ]] && [ "$_DEPSHELPER" != "1" ]; then
    source "$_where"/wine-tkg-scripts/deps
    if [[ "${_ci_build}" != "true" ]] && [ "$_os" = "ubuntu" ]; then
      warning "PLEASE MAKE SURE TO READ https://github.com/Frogging-Family/wine-tkg-git/issues/773 BEFORE ATTEMPTING TO USE \"debuntu\" dependency resolution"
      read -rp "Either press enter to continue, or ctrl+c to leave."
    fi
    if [[ "$_NOLIB64" != "true" ]]; then
      install_deps "64" "${_ci_build}" || {
        error "64-bit dependencies installation failed. Please check the error message and install the missing dependencies manually."
        exit 1
      }
    fi
    if [[ "$_NOLIB32" != "true" ]] && [ "$_NOLIB32" != "wow64" ]; then
      install_deps "32" "${_ci_build}" || {
        error "32-bit dependencies installation failed. Please check the error message and install the missing dependencies manually."
        exit 1
      }
    fi
  fi

  # this script makes external builds already and we don't want the specific pacman-related stuff to interfere, so enforce _EXTERNAL_INSTALL="false" when not building proton-tkg
  if [ "$_EXTERNAL_INSTALL" = "true" ]; then
    _EXTERNAL_INSTALL="false"
  fi

  # disable faudio check so we don't fail to build even if faudio libs are missing
  _faudio_ignorecheck="true"

  if [ -z "$_localbuild" ]; then
    _pkgnaming
  fi

  # remove the faudio pkgname tag as we can't be sure it'll get used even if enabled
  pkgname="${pkgname/-faudio-git/}"
}

nonuser_patcher() {
  if [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW1" =~ [yY] ]]; then
    if [ "$_nopatchmsg" != "true" ]; then
      _fullpatchmsg=" -- ( $_patchmsg )"
    fi
    # Pretty ugly - maybe make it more dynamic? Find?
    msg2 "Applying ${_patchname}"    
    echo -e "\n${_patchname}${_fullpatchmsg}" >>"$_where"/prepare.log
    if [ -n "$_patchpath" ]; then
      if [ -f "${_patchpath%/*}"/mainline/"$_patchname" ] || [ -f "${_patchpath%/*}"/mainline/legacy/"$_patchname" ]; then
        _patchpath="${_patchpath%/*}/mainline/"
      elif [ -f "${_patchpath%/*}"/staging/"$_patchname" ] || [ -f "${_patchpath%/*}"/staging/legacy/"$_patchname" ]; then
        _patchpath="${_patchpath%/*}/staging/"
      fi
      if [ -e "${_patchpath%/*}"/"$_patchname" ]; then
        patch -Np1 <"${_patchpath%/*}"/"$_patchname" >>"$_where"/prepare.log || (error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience." && exit 1)
      elif [ -e "${_patchpath%/*}"/legacy/"$_patchname" ] || [ -e "${_patchpath}"/legacy/"$_patchname" ]; then
        patch -Np1 <"${_patchpath%/*}"/legacy/"$_patchname" >>"$_where"/prepare.log || (error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience." && exit 1)
      elif [ -e "$_where"/"$_patchname" ]; then
        warning "Falling back to root dir patching"
        patch -Np1 <"$_where"/"$_patchname" >>"$_where"/prepare.log || (error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience." && exit 1)
      else
        warning "Patch not found -- Skipping"
      fi
    else
      patch -Np1 <"$_where"/"$_patchname" >>"$_where"/prepare.log || (error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience." && exit 1)
    fi
    echo -e "${_patchname}${_fullpatchmsg}" >>"$_where"/last_build_config.log
  fi
}

build_wine_tkg() {
  ## prepare step
  cd "$srcdir"
  # state tracker start - FEAR THE MIGHTY FROG MINER
  touch "${_where}"/BIG_UGLY_FROGMINER

  if [ "$_SKIPBUILDING" != "true" ]; then
    msg2 "Cloning and preparing sources... Please be patient."
    if [ -z "$_localbuild" ]; then
      _src_init
      _source_cleanup >>"$_where"/prepare.log
      _prepare
    else
      _winesrcdir="$_localbuild"
      _use_staging="false"
      pkgname="$_localbuild"
      echo -e "Building local source $_localbuild" >"$_where"/prepare.log
      if [ -n "$_PKGNAME_OVERRIDE" ]; then
        if [ "$_PKGNAME_OVERRIDE" = "none" ]; then
          pkgname="${pkgname}"
        else
          pkgname="${pkgname}-${_PKGNAME_OVERRIDE}"
        fi
        msg2 "Overriding default pkgname. New pkgname: ${pkgname}"
      fi
    fi
    ## prepare step end
  fi

  if (cd "${srcdir}"/"${_winesrcdir}" && git merge-base --is-ancestor 8c3f205696571558a6fae42314370fbd7cc14a12 HEAD); then
    local _new_makefiles="true"
  else
    local _new_makefiles="false"
  fi

  pkgver=$(pkgver)

  _polish
  _makedirs
  _prebuild_common

  if [ "$_nomakepkg_nover" = "true" ]; then
    _nomakepkg_pkgname="${pkgname}"
  else
    _nomakepkg_pkgname="${pkgname}-${pkgver}"
  fi
  if [ -z "$_nomakepkg_prefix_path" ]; then
    local _prefix="$_where/${_nomakepkg_pkgname}"
  else
    local _prefix="${_nomakepkg_prefix_path}/${_nomakepkg_pkgname}"
  fi

  if [ "$_NOLIB32" = "true" ]; then
    local _lib32name="lib"
    local _lib64name="lib"
  elif [ -e /lib ] && [ -e /lib64 ] && [ -d /usr/lib ] && [ -d /usr/lib32 ] && [ "$_EXTERNAL_INSTALL" != "proton" ]; then
    if [ "$_new_makefiles" = "true" ]; then
      local _lib32name="lib"
    else
      local _lib32name="lib32"
    fi
    local _lib64name="lib"
  else
    if [ "$_new_makefiles" = "true" ]; then
      local _lib32name="lib64"
    else
      local _lib32name="lib"
    fi
    local _lib64name="lib64"
  fi

  # configure args
  if [ -n "$_configure_userargs64" ]; then
    _configure_args64+=($_configure_userargs64)
  fi
  if [ -n "$_configure_userargs32" ]; then
    _configure_args32+=($_configure_userargs32)
  fi

  # External install
  if [ "$_EXTERNAL_INSTALL" = "true" ]; then
    if [ "$_EXTERNAL_NOVER" = "true" ]; then
      _prefix="$_DEFAULT_EXTERNAL_PATH/$pkgname"
    else
      if [ "$_use_staging" = "true" ]; then
        cd "$srcdir/$_stgsrcdir"
      else
        cd "$srcdir/$_winesrcdir"
      fi
      _realwineversion=$(_describe_wine)
      _prefix="$_DEFAULT_EXTERNAL_PATH/$pkgname-$_realwineversion"
    fi
  else
    _configure_args64+=(--libdir="$_prefix/$_lib64name")
    _configure_args32+=(--libdir="$_prefix/$_lib32name")
  fi

  if [ "$_SKIPBUILDING" != "true" ] && [ "$_NOCOMPILE" != "true" ]; then
    _build
  fi

  if [ "$_NOCOMPILE" != "true" ]; then
    _package_nomakepkg
  fi
}

_script_usage() {
    echo "$0 - A non-makepkg build script for wine-tkg-git"
    echo ""
    echo "Usage: $0 [args]"
    echo ""
    echo "  Command-Line Options:"
    echo ""
    echo "    -d|--deps64 :        Check for missing 64-bit dependencies"
    echo "    -e|--deps32 :        Check for missing 32-bit dependencies"
    echo "    -c|--config <path> : Use a custom config file"
    echo ""
    exit 0
}

_script_parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--deps64)
        _DEPSHELPER=1
        ACTION="deps64"
        shift 1
        ;;
      -e|--deps32)
        _DEPSHELPER=1
        ACTION="deps32"
        shift 1
        ;;
      -c|--config)
        if [ -z "$2" ]; then
          error "No path provided for custom config file!"
          exit 1
        fi
        _EXT_CONFIG_PATH="$(readlink -m $2)"
        if [ ! -f "$_EXT_CONFIG_PATH" ]; then
          echo "User-supplied external config file '${_EXT_CONFIG_PATH}' not found! Please fix your passed path!"
          exit 0
        fi
        sed -i -e "s|_EXT_CONFIG_PATH.*|_EXT_CONFIG_PATH=${_EXT_CONFIG_PATH}|" "$_where"/wine-tkg-profiles/advanced-customization.cfg
        shift 1
        ;;
      *)
        _script_usage
        ;;
    esac
    shift
  done
}

_script_main() {
  case "$ACTION" in
    deps64)
      _src_init
      cd "${srcdir}"/"${_winesrcdir}"
      ./configure --enable-win64
      msg2 "You might find help regarding dependencies here: https://github.com/Tk-Glitch/PKGBUILDS/wiki/wine-tkg-git#dependencies"
      ;;
    deps32)
      _src_init
      cd "${srcdir}"/"${_winesrcdir}"
      ./configure
      msg2 "You might find help regarding dependencies here: https://github.com/Tk-Glitch/PKGBUILDS/wiki/wine-tkg-git#dependencies"
      ;;
    build)
      build_wine_tkg
      ;;
  esac
}

_script_parse_args "$@"
trap _exit_cleanup EXIT
_script_init
_script_main

