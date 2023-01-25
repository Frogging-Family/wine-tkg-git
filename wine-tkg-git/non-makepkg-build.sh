#!/bin/bash

# Created by: Tk-Glitch <ti3nou at gmail dot com>

# This script replaces the wine-tkg PKGBUILD's function for use outside of makepkg or on non-pacman distros

## You can check for missing dependencies by running this script with either `--deps64` argument for 64-bit dependencies or `--deps32` argument for 32-bit dependencies :
# ./non-makepkg-build.sh --deps64
# ./non-makepkg-build.sh --deps32

## On a stock Ubuntu 19.04 install, you'll need the following deps as bare minimum to build default wine-tkg (without Faudio/winevulkan):
# pkg-config (or pkgconf) bison flex schedtool libfreetype6-dev xserver-xorg-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev 
# For 32-bit support : gcc-multilib g++-multilib libfreetype6-dev:i386 xserver-xorg-dev:i386 libgstreamer1.0-dev:i386 libgstreamer-plugins-base1.0-dev:i386

## For proton-tkg, the 32-bit dependencies above are required as well as the following additions:
# curl fontforge fonttools libsdl2-dev python3-tk
# !!! _sdl_joy_support="true" (default setting) would require libsdl2-dev:i386 but due to a conflict between libsdl2-dev:i386 and libmirclientcpp-dev (at least on 19.04) you're kinda frogged and should set _sdl_joy_support to "false" to build successfully. You'll lose SDL2 support on 32-bit apps !!!

## You're on your own to resolve additional dependencies you might want to build with, such as Faudio.

pkgname=wine-tkg

_build_in_tmpfs="true"

_esyncsrcdir='esync'
_where="$PWD" # track basedir as different Arch based distros are moving srcdir around

# set srcdir, Arch style
if [ "$_build_in_tmpfs" = "true" ]; then
  rm -rf "$_where"/src
  mkdir -p /tmp/wine-tkg/src
  ln -s /tmp/wine-tkg/src "$_where"
else
  mkdir -p "$_where"/src
fi
srcdir="$_where"/src

# use msg2, error and pkgver funcs for compat
msg2() {
 echo -e " \033[1;34m->\033[1;0m \033[1;1m$1\033[1;0m" >&2
}
error() {
 echo -e " \033[1;31m==> ERROR: $1\033[1;0m" >&2
}
warning() {
 echo -e " \033[1;33m==> WARNING: $1\033[1;0m" >&2
}

pkgver() {
  if [ -d "${srcdir}/${_winesrcdir}" ]; then
	if [ "$_use_staging" = "true" ] && [ -d "${srcdir}/${_stgsrcdir}" ] && [[ "$_custom_wine_source" != *"ValveSoftware"* ]]; then
	  cd "${srcdir}/${_stgsrcdir}"
	else
	  cd "${srcdir}/${_winesrcdir}"
	fi

	# retrieve current wine version - if staging is enabled, staging version will be used instead
	_describe_wine
  fi
}

  # The dependency "helper" (running configure) doesn't have to go through the initial prompt, so skip it
  if [ "$1" = "--deps64" ] || [ "$1" = "--deps32" ]; then
    _DEPSHELPER=1
  fi

  # load functions
  source "$_where"/wine-tkg-scripts/prepare.sh
  source "$_where"/wine-tkg-scripts/build.sh

  msg2 "Non-makepkg build script will be used.\n"

# init step
  _init

  # deps
  if [ -n "$_nomakepkg_dep_resolution_distro" ]; then
    source "$_where"/wine-tkg-scripts/deps
    if [ "$_nomakepkg_dep_resolution_distro" = "debuntu" ]; then
      if [ "$_ci_build" != "true" ]; then
        warning "PLEASE MAKE SURE TO READ https://github.com/Frogging-Family/wine-tkg-git/issues/773 BEFORE ATTEMPTING TO USE \"debuntu\" dependency resolution"
        read -rp "Either press enter to continue, or ctrl+c to leave."
      fi
      _debuntu_64
    elif [ "$_nomakepkg_dep_resolution_distro" = "fedora" ]; then
      _fedora_64
      if [ "$_NOLIB32" != "true" ]; then
        _fedora_32
      fi
    elif [ "$_nomakepkg_dep_resolution_distro" = "archlinux" ]; then
      _archlinux_64
      if [ "$_NOLIB32" != "true" ]; then
        _archlinux_32
      fi
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
# init step end

_nomakepkgsrcinit() {
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
    _winesrcdir=$( sed 's|/|-|g' <<< $(sed 's|.*://.[^/]*/||g' <<< ${_custom_wine_source//./}))
    _winesrctarget="$_custom_wine_source"
  fi

  if [ "$_NUKR" != "debug" ]; then
    $( find "$_where"/wine-tkg-patches -type f '(' -iname '*patch' -or -iname '*.conf' ')' -not -path "*hotfixes*" -exec cp -n {} "$_where" \; ) # copy patches inside the PKGBUILD's dir to preserve makepkg sourcing and md5sum checking
    $( find "$_where"/wine-tkg-userpatches -type f -name "*.my*" -exec cp -n {} "$_where" \; ) # copy userpatches inside the PKGBUILD's dir


    ## Handle git repos similarly to makepkg to preserve repositories when building both with and without makepkg on Arch
    # Wine source
    cd "$_where"
    git clone --mirror "${_winesrctarget}" "$_winesrcdir" 2> "$_where"/prepare.log || true

    # Wine staging source
    git clone --mirror "${_stgsrctarget}" "$_stgsrcdir" 2>> "$_where"/prepare.log || true

    pushd "$srcdir" &>/dev/null

    # Wine staging update and checkout
    cd "$_where"/"${_stgsrcdir}"
    if [[ "${_stgsrctarget}" != "$(git config --get remote.origin.url)" ]] ; then
      echo "${_stgsrcdir} is not a clone of $(git config --get remote.origin.url) (\"${_stgsrctarget}\"). Let's nuke stuff to get back on track, hopefully." >>"$_where"/prepare.log
      rm -rf "$_where/${_stgsrcdir}" && rm -rf "${srcdir}/${_stgsrcdir}"
      warning "Your ${_stgsrcdir} clone was deleted due to remote mismatch (\"${_stgsrctarget}\" differs from \"$(git config --get remote.origin.url)\"). Let's try again with a fresh clone."
      _nomakepkgsrcinit
    fi
    git fetch --all -p
    rm -rf "${srcdir}/${_stgsrcdir}" && git clone "$_where"/"${_stgsrcdir}" "${srcdir}/${_stgsrcdir}"
    cd "${srcdir}"/"${_stgsrcdir}"
    git -c advice.detachedHead=false checkout --force --no-track -B makepkg origin/HEAD
    if [ -n "$_staging_version" ] && [ "$_use_staging" = "true" ]; then
      git -c advice.detachedHead=false checkout "${_staging_version}" 2>> "$_where"/prepare.log
    fi

    # Wine update and checkout
    cd "$_where"/"${_winesrcdir}"
    if [[ "${_winesrctarget}" != "$(git config --get remote.origin.url)" ]] ; then
      echo "${_winesrcdir} is not a clone of $(git config --get remote.origin.url) (\"${_winesrctarget}\"). Let's nuke stuff to get back on track, hopefully." >>"$_where"/prepare.log
      rm -rf "$_where/${_winesrcdir}" && rm -rf "${srcdir}/${_winesrcdir}"
      warning "Your ${_winesrcdir} clone was deleted due to remote mismatch (\"${_winesrctarget}\" differs from \"$(git config --get remote.origin.url)\"). Let's try again with a fresh clone."
      _nomakepkgsrcinit
    fi
    git fetch --all -p
    rm -rf "${srcdir}/${_winesrcdir}" && git clone "$_where"/"${_winesrcdir}" "${srcdir}/${_winesrcdir}"
    cd "${srcdir}"/"${_winesrcdir}"
    git -c advice.detachedHead=false checkout --force --no-track -B makepkg origin/HEAD
    if [ -n "$_plain_version" ] && [ "$_use_staging" != "true" ] || [[ "$_custom_wine_source" = *"ValveSoftware"* ]]; then
      git -c advice.detachedHead=false checkout "${_plain_version}" 2>> "$_where"/prepare.log
      if [ "$_LOCAL_PRESET" = "valve-exp-bleeding" ]; then
        if [ -z "$_bleeding_tag" ]; then
          _bleeding_tag=$(git tag -l --sort=-v:refname | grep "bleeding" | head -n 1)
        fi
        echo -e "Bleeding edge tag: ${_bleeding_tag}" >> "$_where"/prepare.log
        _bleeding_commit=$(git rev-list -n 1 "${_bleeding_tag}")
        echo -e "Bleeding edge commit: ${_bleeding_commit}\n" >> "$_where"/prepare.log
        git -c advice.detachedHead=false checkout "${_bleeding_tag}"
      fi
    fi

    popd &>/dev/null
  fi

  # makepkg proton pkgver loop hack
  if [ "$_ispkgbuild" = "true" ] && [ "$_isfirstloop" = "true" ]; then
    echo "_tmp_ver=\"$(pkgver)\"" >> "$_where"/../proton-tkg/src/proton_tkg_tmp
    exit 0
  fi
}

nonuser_patcher() {
  if [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW1" =~ [yY] ]]; then
    if [ "$_nopatchmsg" != "true" ]; then
      _fullpatchmsg=" -- ( $_patchmsg )"
    fi
    msg2 "Applying ${_patchname}"
    echo -e "\n${_patchname}${_fullpatchmsg}" >> "$_where"/prepare.log
    patch -Np1 < "$_where"/"$_patchname" >> "$_where"/prepare.log || (error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience." && exit 1)
    echo -e "${_patchname}${_fullpatchmsg}" >> "$_where"/last_build_config.log
  fi
}

build_wine_tkg() {

  set -e

  ## prepare step
  cd "$srcdir"
  # state tracker start - FEAR THE MIGHTY FROG MINER
  touch "${_where}"/BIG_UGLY_FROGMINER

  if [ "$_SKIPBUILDING" != "true" ]; then
    msg2 "Cloning and preparing sources... Please be patient."
    if [ -z "$_localbuild" ]; then
      _nomakepkgsrcinit

      _source_cleanup >> "$_where"/prepare.log
      _prepare
    else
      _winesrcdir="$_localbuild"
      _use_staging="false"
      pkgname="$_localbuild"
      echo -e "Building local source $_localbuild" > "$_where"/prepare.log
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

  pkgver=$(pkgver)

  _polish
  _makedirs

  _prebuild_common

  if [ "$_nomakepkg_nover" = "true" ] ; then
    _nomakepkg_pkgname="${pkgname}"
  else
    _nomakepkg_pkgname="${pkgname}-${pkgver}"
  fi
  if [ -z "$_nomakepkg_prefix_path" ]; then
    local _prefix="$_where/${_nomakepkg_pkgname}"
  else
    local _prefix="${_nomakepkg_prefix_path}/${_nomakepkg_pkgname}"
  fi

  if [ -e /lib ] && [ -e /lib64 ] && [ -d /usr/lib ] && [ -d /usr/lib32 ] && [ "$_EXTERNAL_INSTALL" != "proton" ]; then
    local _lib32name="lib32"
    local _lib64name="lib"
  else
    local _lib32name="lib"
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

if [ "$1" = "--deps64" ]; then
  _nomakepkgsrcinit
  cd "${srcdir}"/"${_winesrcdir}"
  ./configure --enable-win64
  msg2 "You might find help regarding dependencies here: https://github.com/Tk-Glitch/PKGBUILDS/wiki/wine-tkg-git#dependencies"
elif [ "$1" = "--deps32" ]; then
  _nomakepkgsrcinit
  cd "${srcdir}"/"${_winesrcdir}"
  ./configure
  msg2 "You might find help regarding dependencies here: https://github.com/Tk-Glitch/PKGBUILDS/wiki/wine-tkg-git#dependencies"
else
  # If $1 contains a path, and it exists, use it as default for config
  if [ -n "$1" ]; then
    _EXT_CONFIG_PATH="$(readlink -m $1)"
    if [ ! -f "$_EXT_CONFIG_PATH" ]; then
      echo "User-supplied external config file '${_EXT_CONFIG_PATH}' not found! Please fix your passed path!"
      exit 0
    fi
    sed -i -e "s|_EXT_CONFIG_PATH.*|_EXT_CONFIG_PATH=${_EXT_CONFIG_PATH}|" "$_where"/wine-tkg-profiles/advanced-customization.cfg
  fi

  build_wine_tkg
fi

trap _exit_cleanup EXIT
