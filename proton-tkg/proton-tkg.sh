#!/bin/bash

# Created by: Tk-Glitch <ti3nou at gmail dot com>

# This script creates Steamplay compatible wine builds based on wine-tkg-git and additional proton patches and libraries.
# It is not standalone and can be considered an addon to wine-tkg-git PKGBUILD and patchsets.

# You can use the uninstall feature by calling the script with "clean" as argument : ./proton-tkg.sh clean
# You can run the vrclient building alone with : ./proton-tkg.sh build_vrclient
# You can run the lsteamclient building alone with : ./proton-tkg.sh build_lsteamclient
# You can run the steamhelper building alone with : ./proton-tkg.sh build_steamhelper
# You can run the mediaconverter building alone with : ./proton-tkg.sh build_mediaconv

set -e

_nowhere="$PWD"
_nomakepkg="true"
_no_steampath="false"

function resources_cleanup {
  # The symlinks switch doesn't need the recursive flag, but we'll use it temporarily
  # as a smoother transition for existing users with dirty trees
  rm -rf "${_nowhere}"/{Proton,vkd3d-proton,dxvk-tools,dxvk,liberation-fonts,mono,gecko,steam-runtime,openvr}
}

trap resources_cleanup EXIT

resources_cleanup

_resources_path="${_nowhere}/external-resources"
mkdir -p "${_resources_path}"/{Proton,vkd3d-proton,dxvk-tools,dxvk,liberation-fonts,mono,gecko,openvr}
ln -s "${_resources_path}"/Proton "${_nowhere}"/Proton
ln -s "${_resources_path}"/vkd3d-proton "${_nowhere}"/vkd3d-proton
ln -s "${_resources_path}"/dxvk-tools "${_nowhere}"/dxvk-tools
ln -s "${_resources_path}"/dxvk "${_nowhere}"/dxvk
ln -s "${_resources_path}"/liberation-fonts "${_nowhere}"/liberation-fonts
ln -s "${_resources_path}"/mono "${_nowhere}"/mono
ln -s "${_resources_path}"/gecko "${_nowhere}"/gecko
ln -s "${_resources_path}"/steam-runtime "${_nowhere}"/steam-runtime
ln -s "${_resources_path}"/openvr "${_nowhere}"/openvr

# Enforce using makepkg when using --makepkg
if [ "$1" = "--makepkg" ]; then
  _nomakepkg="false"
fi

if [ "$_ispkgbuild" = "true" ]; then
  _wine_tkg_git_path="${_nowhere}/../../wine-tkg-git"
  _logdir="$_nowhere/.."
else
  _wine_tkg_git_path="${_nowhere}/../wine-tkg-git" # Change to wine-tkg-git path if needed
  _logdir="$_nowhere"

  # Set Steam root path
  if [ -d "$HOME/.steam/root" ]; then # typical on Arch
    _steampath="$HOME/.steam/root"
    _runtime="$HOME/.steam/root/ubuntu12_32/steam-runtime"
  elif [ -e "$HOME/.steam/steam.sh" ]; then # typical on Ubuntu
    _steampath="$HOME/.steam"
    _runtime="$HOME/.steam/ubuntu12_32/steam-runtime"
  else
    read -rp "Your Steam install wasn't found! Do you want to continue anyway? N/y: " _no_steampath;
    if [ "$_no_steampath" != "y" ]; then
      exit
    fi
  fi

  if [ "$_no_steampath" != "y" ]; then
    # Set Steam config file path
    if [ -e "$HOME/.local/share/Steam/config/config.vdf" ]; then
      _config_file="$HOME/.local/share/Steam/config/config.vdf"
    elif [ -e "$_steampath/steam/config/config.vdf" ]; then
      _config_file="$_steampath/steam/config/config.vdf"
    elif [ -e "$_steampath/config/config.vdf" ]; then
      _config_file="$_steampath/config/config.vdf"
    else
      echo -e "Your Steam config file path wasn't found! Exiting.."
      exit
    fi
  fi
fi

cat <<'EOF'

 ______              __                      __   __
|   __ \.----.-----.|  |_.-----.-----.______|  |_|  |--.-----.
|    __/|   _|  _  ||   _|  _  |     |______|   _|    <|  _  |
|___|   |__| |_____||____|_____|__|__|      |____|__|__|___  |
                                                       |_____|

Also known as "Some kind of build wrapper for wine-tkg-git"

EOF

function new_lib_path_check {
  # We want to track builds using the new lib paths - introduced with 0aa335b1060428f5f799c93e3c6dea2bc2dd864a-79a148e1fa8b5ada2dc8fec03cf866a3d78c0d54

  # i386
  if [ -d "$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-unix" ] && [ ! -d "$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-windows" ]; then # This case shouldn't exist
    _new_lib_paths="true"
    _new_lib_paths_69="false"
    _i386_unix_path="$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-unix/"
    _i386_windows_path="$_nowhere/proton_dist_tmp/$_lib32name/wine/"
    _i386_windows_tail="/$_lib32name/wine"
  elif [ ! -d "$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-unix" ] && [ -d "$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-windows" ] && [ ! -e "$_nowhere"/proton_dist_tmp/$_lib32name/libwine.* ]; then
    _new_lib_paths="true"
    _new_lib_paths_69="false"
    _i386_unix_path="$_nowhere/proton_dist_tmp/$_lib32name/"
    _i386_windows_path="$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-windows/"
    _i386_windows_tail="/$_lib32name/wine/i386-windows"
  elif [ -d "$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-unix" ] && [ -d "$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-windows" ] && [ ! -e "$_nowhere"/proton_dist_tmp/$_lib32name/libwine.* ]; then
    _new_lib_paths="true"
    _new_lib_paths_69="true"
    _i386_unix_path="$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-unix/"
    _i386_windows_path="$_nowhere/proton_dist_tmp/$_lib32name/wine/i386-windows/"
    _i386_windows_tail="/$_lib32name/wine/i386-windows"
  else
    _new_lib_paths="false"
    _new_lib_paths_69="false"
    _i386_unix_path="$_nowhere/proton_dist_tmp/$_lib32name/"
    _i386_windows_path="$_nowhere/proton_dist_tmp/$_lib32name/wine/"
    _i386_windows_tail="/$_lib32name/wine"
  fi

  # x86_64
  if [ -d "$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-unix" ] && [ ! -d "$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-windows" ]; then # This case shouldn't exist
    _new_lib_paths="true"
    _new_lib_paths_69="false"
    _x86_64_unix_path="$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-unix/"
    _x86_64_windows_path="$_nowhere/proton_dist_tmp/$_lib64name/wine/"
    _x86_64_windows_tail="/$_lib64name/wine"
  elif [ ! -d "$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-unix" ] && [ -d "$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-windows" ] && [ ! -e "$_nowhere"/proton_dist_tmp/$_lib64name/libwine.* ]; then
    _new_lib_paths="true"
    _new_lib_paths_69="false"
    _x86_64_unix_path="$_nowhere/proton_dist_tmp/$_lib64name/"
    _x86_64_windows_path="$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-windows/"
    _x86_64_windows_tail="$_lib64name/wine/x86_64-windows"
  elif [ -d "$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-unix" ] && [ -d "$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-windows" ] && [ ! -e "$_nowhere"/proton_dist_tmp/$_lib64name/libwine.* ]; then
    _new_lib_paths="true"
    _new_lib_paths_69="true"
    _x86_64_unix_path="$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-unix/"
    _x86_64_windows_path="$_nowhere/proton_dist_tmp/$_lib64name/wine/x86_64-windows/"
    _x86_64_windows_tail="$_lib64name/wine/x86_64-windows"
  else
    _new_lib_paths="false"
    _new_lib_paths_69="false"
    _x86_64_unix_path="$_nowhere/proton_dist_tmp/$_lib64name/"
    _x86_64_windows_path="$_nowhere/proton_dist_tmp/$_lib64name/wine/"
    _x86_64_windows_tail="/$_lib64name/wine"
  fi

  echo "_i386_unix_path=$_i386_unix_path" >>"$_logdir"/proton-tkg.log 2>&1
  echo "_i386_windows_path=$_i386_windows_path" >>"$_logdir"/proton-tkg.log 2>&1
  echo "_x86_64_unix_path=$_x86_64_unix_path" >>"$_logdir"/proton-tkg.log 2>&1
  echo "_x86_64_windows_path=$_x86_64_windows_path" >>"$_logdir"/proton-tkg.log 2>&1
}

function build_vrclient {
  cd "$_nowhere"
  source "$_nowhere/proton_tkg_token"
  git clone https://github.com/ValveSoftware/openvr.git || true # It'll complain the path already exists on subsequent builds
  cd openvr
  git reset --hard HEAD
  git clean -xdf
  git pull origin master
  #git checkout 52065df3d6f3af96300dac98cdf7397f26abfcd7
  #cd ..

  export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls --nomsvcrt --dll -I$_nowhere/proton_dist_tmp/include/wine/windows/ -I$_nowhere/proton_dist_tmp/include/ -I$_nowhere/proton_dist_tmp/include/wine/"
  export CFLAGS="-O2 -g"
  export CXXFLAGS="-Wno-attributes -std=c++0x -O2 -g"
  PATH="$_nowhere"/proton_dist_tmp/bin:$PATH
  if [[ "$_proton_branch" = *6.* ]] || [[ "$_proton_branch" = *7.* ]]; then
    WINEMAKERFLAGS+=" -ldl"
  elif [ "$_standard_dlopen" = "true" ] && [[ "$_proton_branch" != *5.13 ]]; then
    patch -Np1 < "$_nowhere/proton_template/vrclient-remove-library.h-dep.patch" || exit 1
    patch -Np1 < "$_nowhere/proton_template/vrclient-use_standard_dlopen_instead_of_the_libwine_wrappers.patch" || exit 1
    WINEMAKERFLAGS+=" -ldl"
  elif [[ "$_proton_branch" = *5.13 ]]; then
    patch -Np1 < "$_nowhere/proton_template/vrclient-remove-library.h-dep.patch" || exit 1
    WINEMAKERFLAGS+=" -ldl"
  fi

  new_lib_path_check

  rm -rf build/vrclient.win64
  rm -rf build/vrclient.win32
  mkdir -p build/vrclient.win64
  mkdir -p build/vrclient.win32

  cp -a "${_nowhere}"/Proton/vrclient_x64/* build/vrclient.win64
  cp -a "${_nowhere}"/Proton/vrclient_x64/* build/vrclient.win32 && mv build/vrclient.win32/vrclient_x64 build/vrclient.win32/vrclient && mv build/vrclient.win32/vrclient/vrclient_x64.spec build/vrclient.win32/vrclient/vrclient.spec

  cd build/vrclient.win64
  winemaker $WINEMAKERFLAGS -L"$_nowhere/proton_dist_tmp/$_lib64name/" -L"$_nowhere/proton_dist_tmp/$_lib64name/wine/" -I"$_nowhere/openvr/build/vrclient.win64/vrclient_x64/" -I"$_nowhere/openvr/build/vrclient.win64/" vrclient_x64
  make -e CC="winegcc -m64" CXX="wineg++ -m64 $_cxx_addon" -C "$_nowhere/openvr/build/vrclient.win64/vrclient_x64" -j$(nproc) && strip --strip-debug vrclient_x64/vrclient_x64.dll.so || exit 1
  winebuild --dll --fake-module -E "$_nowhere/openvr/build/vrclient.win64/vrclient_x64/vrclient_x64.spec" -o vrclient_x64.dll.fake || exit 1
  cd ../..

  cd build/vrclient.win32
  if [ "$_NOLIB32" != "true" ]; then
    winemaker $WINEMAKERFLAGS --wine32 -L"$_nowhere/proton_dist_tmp/$_lib32name/" -L"$_nowhere/proton_dist_tmp/$_lib32name/wine/" -I"$_nowhere/openvr/build/vrclient.win32/vrclient/" -I"$_nowhere/openvr/build/vrclient.win32/" vrclient
    make -e CC="winegcc -m32" CXX="wineg++ -m32 $_cxx_addon" -C "$_nowhere/openvr/build/vrclient.win32/vrclient" -j$(nproc) && strip --strip-debug vrclient/vrclient.dll.so || exit 1
  fi
  winebuild --dll --fake-module -E "$_nowhere/openvr/build/vrclient.win32/vrclient/vrclient.spec" -o vrclient.dll.fake || exit 1
  cd "$_nowhere"

  mkdir -p proton_dist_tmp/lib/wine/dxvk
  mkdir -p proton_dist_tmp/lib64/wine/dxvk
  cp -v "${_nowhere}"/openvr/bin/win32/openvr_api.dll proton_dist_tmp/lib/wine/dxvk/openvr_api_dxvk.dll
  cp -v "${_nowhere}"/openvr/bin/win64/openvr_api.dll proton_dist_tmp/lib64/wine/dxvk/openvr_api_dxvk.dll

  if [ "$_new_lib_paths" = "true" ]; then
    if [ "$_new_lib_paths_69" = "true" ] && [ -d proton_dist_tmp/$_lib32name/wine/i386-windows ] && [ -d proton_dist_tmp/$_lib64name/wine/x86_64-windows ]; then
      cp -v "${_nowhere}"/openvr/build/vrclient.win64/vrclient_x64/vrclient_x64.dll.so proton_dist_tmp/$_lib64name/wine/x86_64-unix/ && cp -v "${_nowhere}"/openvr/build/vrclient.win64/vrclient_x64.dll.fake proton_dist_tmp/$_lib64name/wine/x86_64-windows/vrclient_x64.dll
      if [ "$_NOLIB32" != "true" ]; then
        cp -v "${_nowhere}"/openvr/build/vrclient.win32/vrclient/vrclient.dll.so proton_dist_tmp/$_lib32name/wine/i386-unix/
      fi
      cp -v "${_nowhere}"/openvr/build/vrclient.win32/vrclient.dll.fake proton_dist_tmp/$_lib32name/wine/i386-windows/vrclient.dll
    fi
  else
    cp -v "${_nowhere}"/openvr/build/vrclient.win64/vrclient_x64/vrclient_x64.dll.so proton_dist_tmp/$_lib64name/wine/ && cp -v "${_nowhere}"/openvr/build/vrclient.win64/vrclient_x64.dll.fake proton_dist_tmp/$_lib64name/wine/fakedlls/vrclient_x64.dll
    cp -v "${_nowhere}"/openvr/build/vrclient.win32/vrclient/vrclient.dll.so proton_dist_tmp/$_lib32name/wine/ && cp -v "${_nowhere}"/openvr/build/vrclient.win32/vrclient.dll.fake proton_dist_tmp/$_lib32name/wine/fakedlls/vrclient.dll
  fi
}

function build_lsteamclient {
  cd "$_nowhere"/Proton
  source "$_nowhere/proton_tkg_token"
  export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls --nomsvcrt -I$_nowhere/proton_dist_tmp/include/wine -I$_wine_tkg_git_path/src/$_winesrcdir/include -I$_wine_tkg_git_path/src/$_winesrcdir/include/wine"
  export CFLAGS="-Wno-attributes -O2 -g"
  export CXXFLAGS="-fpermissive -Wno-attributes -O2 -g"
  export PATH="$_nowhere"/proton_dist_tmp/bin:$PATH
  if [[ "$_proton_branch" != *3.* ]] && [[ "$_proton_branch" != *4.* ]]; then
    _cxx_addon="-std=gnu++11"
    if [[ "$_proton_branch" = *5.0 ]] && [ "$_standard_dlopen" = "true" ]; then
      patch -Np1 < "$_nowhere/proton_template/steamclient-remove-library.h-dep.patch" || exit 1
      patch -Np1 < "$_nowhere/proton_template/steamclient-use_standard_dlopen_instead_of_the_libwine_wrappers.patch" || exit 1
      WINEMAKERFLAGS+=" -ldl"
    elif [[ "$_proton_branch" = *5.13 ]]; then
      patch -Np1 < "$_nowhere/proton_template/steamclient-remove-library.h-dep.patch" || exit 1
      WINEMAKERFLAGS+=" -ldl"
    else
      WINEMAKERFLAGS+=" -ldl"
    fi
  fi

  new_lib_path_check

  rm -rf build/lsteamclient.win64
  rm -rf build/lsteamclient.win32
  mkdir -p build/lsteamclient.win64
  mkdir -p build/lsteamclient.win32

  cp -a lsteamclient/* build/lsteamclient.win64
  cp -a lsteamclient/* build/lsteamclient.win32

  cd build/lsteamclient.win64
  winemaker $WINEMAKERFLAGS --dll -DSTEAM_API_EXPORTS -Dprivate=public -Dprotected=public .
  sed -re 's@_LDFLAGS=@_LDFLAGS= -static-libgcc -static-libstdc++ -ldl @' -i "$_nowhere/Proton/build/lsteamclient.win64/Makefile"
  make -e CC="winegcc -m64" CXX="wineg++ -m64 $_cxx_addon" -C "$_nowhere/Proton/build/lsteamclient.win64" -j$(nproc) && strip --strip-debug lsteamclient.dll.so || exit 1
  if [ "$_new_lib_paths_69" = "true" ]; then
    touch "$_nowhere/Proton/build/lsteamclient.win64/steamclient.spec"
    winebuild --dll --fake-module -m64 -E "$_nowhere/Proton/build/lsteamclient.win64/steamclient.spec" --dll-name=lsteamclient -o lsteamclient.dll.fake || exit 1
  fi
  cd ../..

  cd build/lsteamclient.win32
  if [ "$_NOLIB32" != "true" ]; then
    winemaker $WINEMAKERFLAGS --dll -DSTEAM_API_EXPORTS -Dprivate=public -Dprotected=public --wine32 .
    sed -re 's@_LDFLAGS=@_LDFLAGS= -static-libgcc -static-libstdc++ -ldl @' -i "$_nowhere/Proton/build/lsteamclient.win32/Makefile"
    make -e CC="winegcc -m32" CXX="wineg++ -m32 $_cxx_addon" -C "$_nowhere/Proton/build/lsteamclient.win32" -j$(nproc) && strip --strip-debug lsteamclient.dll.so || exit 1
  fi
  if [ "$_new_lib_paths_69" = "true" ]; then
    touch "$_nowhere/Proton/build/lsteamclient.win32/steamclient.spec"
    winebuild --dll --fake-module -m32 -E "$_nowhere/Proton/build/lsteamclient.win32/steamclient.spec" --dll-name=lsteamclient -o lsteamclient.dll.fake || exit 1
  fi
  cd "$_nowhere"

  # Inject lsteamclient libs in our wine-tkg-git build
  if [ "$_new_lib_paths" = "true" ]; then
    if [ "$_new_lib_paths_69" = "true" ]; then
      cp -v Proton/build/lsteamclient.win64/lsteamclient.dll.so proton_dist_tmp/$_lib64name/wine/x86_64-unix/
      if [ "$_NOLIB32" != "true" ]; then
        cp -v Proton/build/lsteamclient.win32/lsteamclient.dll.so proton_dist_tmp/$_lib32name/wine/i386-unix/
      fi
    else
      cp -v Proton/build/lsteamclient.win64/lsteamclient.dll.so proton_dist_tmp/$_lib64name/wine/
      cp -v Proton/build/lsteamclient.win32/lsteamclient.dll.so proton_dist_tmp/$_lib32name/wine/
    fi
    if [ "$_new_lib_paths_69" = "true" ] && [ -d proton_dist_tmp/$_lib32name/wine/i386-windows ] && [ -d proton_dist_tmp/$_lib64name/wine/x86_64-windows ]; then
      cp -v Proton/build/lsteamclient.win64/lsteamclient.dll.fake proton_dist_tmp/$_lib64name/wine/x86_64-windows/lsteamclient.dll
      cp -v Proton/build/lsteamclient.win32/lsteamclient.dll.fake proton_dist_tmp/$_lib32name/wine/i386-windows/lsteamclient.dll
    fi
  else
    cp -v Proton/build/lsteamclient.win64/lsteamclient.dll.so proton_dist_tmp/$_lib64name/wine/
    cp -v Proton/build/lsteamclient.win32/lsteamclient.dll.so proton_dist_tmp/$_lib32name/wine/
    cp -v Proton/build/lsteamclient.win64/lsteamclient.dll.fake proton_dist_tmp/$_lib64name/wine/fakedlls/lsteamclient.dll
    cp -v Proton/build/lsteamclient.win32/lsteamclient.dll.fake proton_dist_tmp/$_lib32name/wine/fakedlls/lsteamclient.dll
  fi
}

function build_vkd3d {
  cd "$_nowhere"
  source "$_nowhere/proton_tkg_token"
  git clone https://github.com/HansKristian-Work/vkd3d-proton.git || true # It'll complain the path already exists on subsequent builds
  cd vkd3d-proton
  git reset --hard HEAD
  git clean -xdf
  git pull origin master
  git submodule update --init --recursive

  if [ "$_bump_dxil_spirv" = "true" ]; then
    ( cd subprojects/dxil-spirv && git pull origin master )
  fi

  _user_patches_no_confirm="true"
  _userpatch_target="vkd3d-proton"
  _userpatch_ext="myvkd3d"
  proton_patcher

  rm -rf build/lib64-vkd3d
  rm -rf build/lib32-vkd3d
  mkdir -p build/lib64-vkd3d
  mkdir -p build/lib32-vkd3d

  unset CFLAGS
  unset CPPFLAGS
  unset CXXFLAGS
  unset LDFLAGS

  meson --cross-file build-win64.txt --buildtype release --strip -Denable_tests=false --prefix "$_nowhere"/vkd3d-proton/build/lib64-vkd3d "$_nowhere"/vkd3d-proton/build/lib64-vkd3d
  cd "$_nowhere"/vkd3d-proton/build/lib64-vkd3d && ninja install
  cd "$_nowhere"/vkd3d-proton

  meson --cross-file build-win32.txt --buildtype release --strip -Denable_tests=false --prefix "$_nowhere"/vkd3d-proton/build/lib32-vkd3d "$_nowhere"/vkd3d-proton/build/lib32-vkd3d
  cd "$_nowhere"/vkd3d-proton/build/lib32-vkd3d && ninja install

  cd "$_nowhere"
}

function build_dxvk {
  cd "$_nowhere"
  git clone https://github.com/Frogging-Family/dxvk-tools.git || true # It'll complain the path already exists on subsequent builds
  cd dxvk-tools
  git reset --hard HEAD
  git clean -xdf
  git pull origin master

  if [ -e "$_nowhere"/proton-tkg-userpatches/*.mydxvk* ]; then
    cp "$_nowhere"/proton-tkg-userpatches/*.mydxvk* DXVKBUILD/patches/
  fi

  ./updxvk build
  _proton_tkg_path="proton-tkg" ./updxvk proton-tkg

  cd "$_nowhere"
}

function build_dxvk_nvapi {
  cd "$_nowhere"/Proton
  git clone https://github.com/jp7677/dxvk-nvapi.git || true # It'll complain the path already exists on subsequent builds
  cd dxvk-nvapi
  git reset --hard HEAD
  git clean -xdf
  git pull origin master
  git submodule update --init --recursive

  rm -rf "$_nowhere"/Proton/build/lib64-dxvk-nvapi
  rm -rf "$_nowhere"/Proton/build/lib32-dxvk-nvapi
  mkdir -p "$_nowhere"/Proton/build/lib64-dxvk-nvapi
  mkdir -p "$_nowhere"/Proton/build/lib32-dxvk-nvapi

  unset CFLAGS
  unset CPPFLAGS
  unset CXXFLAGS
  unset LDFLAGS

  cd "$_nowhere"/Proton/dxvk-nvapi && ./package-release.sh master "$_nowhere"/Proton/build

  cd "$_nowhere"
}

function build_mediaconverter {

  mkdir -p "$_nowhere/gst/lib64/gstreamer-1.0"
  mkdir -p "$_nowhere/gst/lib/gstreamer-1.0"

  if [ "$_build_gstreamer" = "true" ]; then
    if [ -n "$_runtime" ]; then
      "$_nowhere"/steam-runtime/run.sh "$_nowhere"/proton_template/gstreamer.sh
    else
      "$_nowhere"/proton_template/gstreamer.sh
    fi
  fi

  if [ "$_build_mediaconv" = "true" ]; then
    if [ -d "$_nowhere"/Proton/media-converter ]; then
      cd "$_nowhere"/Proton/media-converter

      # 32-bit
      if [ "$_NOLIB32" != "true" ]; then
        mkdir -p "$_nowhere"/Proton/build/mediaconv32
        rm -rf "$_nowhere"/Proton/build/mediaconv32/*
        ( if [ -d '/usr/lib32/pkgconfig' ]; then # Typical Arch path
          export PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib/pkgconfig:/usr/lib32/pkgconfig"
        elif [ -d '/usr/lib/i386-linux-gnu/pkgconfig' ]; then # Ubuntu 18.04/19.04 path
          export PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib/pkgconfig:/usr/lib/i386-linux-gnu/pkgconfig"
        else
          export PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib/pkgconfig:/usr/lib/pkgconfig" # Pretty common path, possibly helpful for OpenSuse & Fedora
        fi
        PKG_CONFIG_ALLOW_CROSS=1 cargo build --target i686-unknown-linux-gnu --target-dir "$_nowhere"/Proton/build/mediaconv32 --release )

        cp -a "$_nowhere"/Proton/build/mediaconv32/i686-unknown-linux-gnu/release/libprotonmediaconverter.so "$_nowhere"/gst/lib/gstreamer-1.0/
      fi

      # 64-bit
      mkdir -p "$_nowhere"/Proton/build/mediaconv64
      rm -rf "$_nowhere"/Proton/build/mediaconv64/*
      ( if [ ! -d '/usr/lib32' ]; then # Fedora
        PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib64/pkgconfig:/usr/lib64/pkgconfig"
      elif [ -d '/usr/lib32' ] && [ -d '/usr/lib' ] && [ -e '/usr/lib64' ]; then # Arch
        PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib64/pkgconfig:/usr/lib/pkgconfig"
      fi
      cargo build --target x86_64-unknown-linux-gnu --target-dir "$_nowhere"/Proton/build/mediaconv64 --release )

      cp -a "$_nowhere"/Proton/build/mediaconv64/x86_64-unknown-linux-gnu/release/libprotonmediaconverter.so "$_nowhere"/gst/lib64/gstreamer-1.0/
    fi
  fi

  strip --strip-unneeded "$_nowhere"/gst/lib/gstreamer-1.0/*.so || true
  strip --strip-unneeded "$_nowhere"/gst/lib64/gstreamer-1.0/*.so || true

  cd "$_nowhere"
}

function build_steamhelper {
  export CFLAGS="-Wno-attributes -O2 -g"
  export CXXFLAGS="-Wno-attributes -O2 -g"
  # disable openvr support for now since we don't support it
  if [[ "$_proton_branch" = *6.3 ]]; then
    _cxx_addon="-std=c++17"
    if [ "$_no_loader_array" = "true" ]; then
      if [ "$_steamvr_support" != "true" ]; then
        ( cd Proton && patch -Np1 -R < "$_nowhere/proton_template/steamhelper_revert_openvr-support-legacy.patch" ) || exit 1
      fi
    else
      if [ -d "$_nowhere"/Proton/steam_helper/64 ]; then
        ( cd Proton && patch -Np1 < "$_nowhere/proton_template/steamhelper_remove__wine_make_process_system2.patch" ) || exit 1
        #( cd Proton && patch -Np1 < "$_nowhere/proton_template/SHGetFolderPathW_nuke.patch" ) || exit 1
      else
        ( cd Proton && patch -Np1 < "$_nowhere/proton_template/steamhelper_remove__wine_make_process_system.patch" || exit 1 )
      fi
      if [ "$_steamvr_support" != "true" ]; then
        ( cd Proton && patch -Np1 -R < "$_nowhere/proton_template/steamhelper_revert_openvr-support.patch" ) || exit 1
      fi
    fi
  fi

  if [ "$_processinfoclass" = "true" ]; then
    ( cd Proton && patch -Np1 < "$_nowhere/proton_template/steamhelper_PROCESSINFOCLASS.patch" ) || exit 1
  fi

  if [[ $_proton_branch != *3.* ]]; then
    source "$_nowhere/proton_tkg_token" || true

    rm -rf Proton/build/steam.win32
    mkdir -p Proton/build/steam.win32
    cp -a Proton/steam_helper/* Proton/build/steam.win32

    rm -rf Proton/build/steam.win64
    mkdir -p Proton/build/steam.win64
    cp -a Proton/steam_helper/* Proton/build/steam.win64

    cd Proton/build/steam.win32

    new_lib_path_check

    if [[ "$_proton_branch" = *4.11 ]]; then
      export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls -I$_nowhere/proton_dist_tmp/include/wine -I$_wine_tkg_git_path/src/$_winesrcdir/include -I$_wine_tkg_git_path/src/$_winesrcdir/include/wine -I$_nowhere/proton_dist_tmp/include/wine/msvcrt"
      winemaker $WINEMAKERFLAGS --wine32 --guiexe -lsteam_api -lole32 -I"$_nowhere/Proton/lsteamclient/steamworks_sdk_142/" -I"$_nowhere/openvr/headers/" -L"$_nowhere/Proton/steam_helper" .
    else
      export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls --nomsvcrt -I$_nowhere/proton_dist_tmp/include/wine -I$_wine_tkg_git_path/src/$_winesrcdir/include -I$_wine_tkg_git_path/src/$_winesrcdir/include/wine"
      winemaker $WINEMAKERFLAGS --wine32 --guiexe -lsteam_api -lole32 -I"$_nowhere/Proton/lsteamclient/steamworks_sdk_142/" -I"$_nowhere/openvr/headers/" -L"$_nowhere/Proton/steam_helper" .
    fi

    if [ "$_NOLIB32" != "true" ]; then
      # 32-bit
      if [ -e "$_nowhere"/Proton/steam_helper/32/libsteam_api.so ]; then
        make -e CC="winegcc -m32" CXX="wineg++ -m32 $_cxx_addon" -C "$_nowhere/Proton/build/steam.win32" LIBRARIES="-L$_nowhere/Proton/steam_helper/32/ -lsteam_api -lole32 -lmsi -ldl -static-libgcc -static-libstdc++" -j$(nproc) && strip --strip-debug steam.exe.so || exit 1
      else
        make -e CC="winegcc -m32" CXX="wineg++ -m32 $_cxx_addon" -C "$_nowhere/Proton/build/steam.win32" LIBRARIES="-lsteam_api -lole32 -ldl -static-libgcc -static-libstdc++" -j$(nproc) && strip --strip-debug steam.exe.so || exit 1
      fi
    fi

    if [ "$_new_lib_paths_69" = "true" ]; then
      touch "$_nowhere/Proton/build/steam.win32/steam.spec"
      winebuild --exe --fake-module -m32 -E "$_nowhere/Proton/build/steam.win32/steam.spec" --dll-name=steam -o steam.exe.fake || exit 1
    fi

    # 64-bit
    if [ -e "$_nowhere"/Proton/steam_helper/64/libsteam_api.so ]; then
      cd "$_nowhere"/Proton/build/steam.win64
      winemaker $WINEMAKERFLAGS --guiexe -lsteam_api -lole32 -I"$_nowhere/Proton/lsteamclient/steamworks_sdk_142/" -I"$_nowhere/openvr/headers/" -L"$_nowhere/Proton/steam_helper" .
      make -e CC="winegcc -m64" CXX="wineg++ -m64 $_cxx_addon" -C "$_nowhere/Proton/build/steam.win64" LIBRARIES="-L$_nowhere/Proton/steam_helper/64/ -lsteam_api -lmsi -lole32 -ldl -static-libgcc -static-libstdc++" -j$(nproc) && strip --strip-debug steam.exe.so


      touch "$_nowhere/Proton/build/steam.win64/steam.spec"
      winebuild --exe --fake-module -m64 -E "$_nowhere/Proton/build/steam.win64/steam.spec" --dll-name=steam -o steam.exe.fake || exit 1
    fi

    cd "$_nowhere"

    if [ "$_new_lib_paths" = "true" ]; then
      # .exe 32 - always there
      cp -v Proton/build/steam.win32/steam.exe.fake proton_dist_tmp/$_lib32name/wine/i386-windows/steam.exe
      # .exe 64
      if [ -e Proton/build/steam.win64/steam.exe.fake ]; then
        cp -v Proton/build/steam.win64/steam.exe.fake proton_dist_tmp/$_lib64name/wine/x86_64-windows/steam.exe
      fi
      if [ "$_new_lib_paths_69" = "true" ]; then
        if [ "$_NOLIB32" != "true" ]; then
          # .so 32
          if [ -e Proton/build/steam.win32/steam.exe.so ]; then
            cp -v Proton/build/steam.win32/steam.exe.so proton_dist_tmp/$_lib32name/wine/i386-unix/
          fi
        fi
        # .so 64
        if [ -e Proton/build/steam.win64/steam.exe.so ]; then
          cp -v Proton/build/steam.win64/steam.exe.so proton_dist_tmp/$_lib64name/wine/x86_64-unix/
        fi
      else
        # .so 32 - always there
        cp -v Proton/build/steam.win32/steam.exe.so proton_dist_tmp/$_lib32name/wine/
      fi
      # .so 32
      if [ -e Proton/build/steam.win32/libsteam_api.so ]; then
        cp -v Proton/build/steam.win32/libsteam_api.so proton_dist_tmp/$_lib32name/
      fi
      # .so 64
      if [ -e Proton/build/steam.win64/32/libsteam_api.so ]; then
        cp -v Proton/build/steam.win64/32/libsteam_api.so proton_dist_tmp/$_lib32name/
        cp -v Proton/build/steam.win64/64/libsteam_api.so proton_dist_tmp/$_lib64name/
      fi
    else
      cp -v Proton/build/steam.win32/steam.exe.fake proton_dist_tmp/$_lib32name/wine/fakedlls/steam.exe
      cp -v Proton/build/steam.win32/steam.exe.so proton_dist_tmp/$_lib32name/wine/
      cp -v Proton/build/steam.win32/libsteam_api.so proton_dist_tmp/$_lib32name/
    fi
  fi
}

proton_patcher() {
	local _patches=("$_nowhere"/proton-tkg-userpatches/*."${_userpatch_ext}revert")
	if [ ${#_patches[@]} -ge 2 ] || [ -e "${_patches}" ]; then
	  if [ "$_user_patches_no_confirm" != "true" ]; then
	    echo "Found ${#_patches[@]} 'to revert' userpatches for ${_userpatch_target}:"
	    printf '%s\n' "${_patches[@]}"
	    read -rp "Do you want to install it/them? - Be careful with that ;)"$'\n> N/y : ' _CONDITION;
	  fi
	  if [[ "$_CONDITION" =~ [yY] ]] || [ "$_user_patches_no_confirm" = "true" ]; then
	    for _f in ${_patches[@]}; do
	      if [ -e "${_f}" ]; then
	        echo "######################################################"
	        echo ""
	        echo "Reverting your own ${_userpatch_target} patch ${_f}"
	        echo ""
	        echo "######################################################"
	        patch -Np1 -R < "${_f}"
	      fi
	    done
	  fi
	fi

	_patches=("$_nowhere"/proton-tkg-userpatches/*."${_userpatch_ext}patch")
	if [ "${#_patches[@]}" -ge 2 ] || [ -e "${_patches}" ]; then
	  if [ "$_user_patches_no_confirm" != "true" ]; then
	    echo "Found ${#_patches[@]} userpatches for ${_userpatch_target}:"
	    printf '%s\n' "${_patches[@]}"
	    read -rp "Do you want to install it/them? - Be careful with that ;)"$'\n> N/y : ' _CONDITION;
	  fi
	  if [[ "$_CONDITION" =~ [yY] ]] || [ "$_user_patches_no_confirm" = "true" ]; then
	    for _f in ${_patches[@]}; do
	      if [ -e "${_f}" ]; then
	        echo "######################################################"
	        echo ""
	        echo "Applying your own ${_userpatch_target} patch ${_f}"
	        echo ""
	        echo "######################################################"
	        patch -Np1 < "${_f}"
	      fi
	    done
	  fi
	fi
}

function steam_is_running {
  if pgrep -x steam >/dev/null; then
    echo "###################################################"
    echo ""
    echo " Steam is running. Please full close it to proceed."
    echo ""
    echo "###################################################"
    echo ""
    read -rp "Press enter when ready..."
    steam_is_running
  fi
}

function wine_is_running {
  pidof -q wineserver || return 0
  echo -e "\n Wineserver is running. Waiting for it to finish..."
  sleep 3
  wine_is_running
}

function proton_tkg_uninstaller {
  # Never cross the Proton streams!
  i=0
  for _proton_tkg in "$_steampath/compatibilitytools.d"/proton_tkg_*; do
    if [ -d "$_proton_tkg" ]; then
      _GOTCHA="$_proton_tkg" && ((i+=1))
    fi
  done

  if [ -d "$_GOTCHA" ] && [ $i -ge 2 ]; then
    cd "$_steampath/compatibilitytools.d"

    _available_builds=( `ls -d proton_tkg_* | sort -V` )
    _strip_builds="${_available_builds[@]//proton_tkg_/}"

    steam_is_running

    cp "$_config_file" "$_config_file".bak && echo "Your config.vdf file was backed up from $_config_file (.bak)" && echo ""

    echo "What Proton-tkg build do you want to uninstall?"

    i=1
    if [ -n "$_just_built" ]; then
      _newest_build="${_just_built//proton_tkg_/}"
      for build in ${_strip_builds[@]//$_newest_build/}; do
        echo "  $i - $build" && ((i+=1))
      done
    else
      for build in ${_strip_builds[@]}; do
        echo "  $i - $build" && ((i+=1))
      done
    fi

    read -rp "choice [1-$(($i-1))]: " _to_uninstall;

    i=1
    for build in ${_strip_builds[@]}; do
      if [ "$_to_uninstall" = "$i" ]; then
        if [ -n "$_just_built" ]; then
          rm -rf "proton_tkg_$build" && _available_builds=( `ls -d proton_tkg_* | sort -V` )
          sed -i "s/\"Proton-tkg $build\"/\"Proton-tkg ${_newest_build}\"/;s/\"TKG-proton-$build\"/\"TKG-proton-${_newest_build}\"/" "$_config_file"
        else
          rm -rf "proton_tkg_$build" && _available_builds=( `ls -d proton_tkg_* | sort -V` ) && _newest_build="${_available_builds[-1]//proton_tkg_/}"
          sed -i "s/\"Proton-tkg $build\"/\"Proton-tkg ${_newest_build[@]}\"/;s/\"TKG-proton-$build\"/\"TKG-proton-${_newest_build[@]}\"/" "$_config_file"
        fi
        echo "###########################################################################################################################"
        echo ""
        echo "Proton-tkg $build was uninstalled and games previously depending on it will now use Proton-tkg ${_newest_build[@]} instead."
        echo ""
        echo "###########################################################################################################################"
      fi
      ((i+=1))
    done

    echo ""
    read -rp "Wanna uninstall more? N/y: " _uninstall_more;
    echo ""
    if [[ "$_uninstall_more" =~ [yY] ]]; then
      proton_tkg_uninstaller
    fi
  elif [ -d "$_GOTCHA" ] && [ $i -eq 1 ]; then
    echo "This tool requires at least two Proton-tkg builds installed in $_steampath/compatibilitytools.d/ and only one was found."
  else
    echo "No Proton-tkg installation found in $_steampath/compatibilitytools.d/"
  fi
}

function setup_dxvk_version_url {
  _dxvk_version_base_url="https://api.github.com/repos/doitsujin/dxvk/releases"
  if [ "${_dxvk_version}" = "" ] || [ "${_dxvk_version}" = "latest" ]; then
      _dxvk_version_url="${_dxvk_version_base_url}/latest"
      # in case of default "" set it to "latest" too
      _dxvk_version="latest"
  else
      _dxvk_version_url="${_dxvk_version_base_url}/tags/${_dxvk_version}"
  fi
}

function download_dxvk_version {
  while true ; do
      setup_dxvk_version_url
      # If anything goes wrong we get exit code 22 from "curl -f"
      set +e
      _dxvk_version_response=$(curl -s -f "$_dxvk_version_url")
      _dxvk_version_response_status=$?
      set -e
      if [ $_dxvk_version_response_status -eq 0 ]; then
        echo "#######################################################"
        echo ""
        echo " Downloading ${_dxvk_version} DXVK release from github for you..."
        echo ""
        echo "#######################################################"
        echo ""
        echo "$_dxvk_version_response" \
        | grep "browser_download_url.*tar.gz" \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | wget -qi -
        break
      else
        echo ""
        echo "#######################################################"
        echo ""
        echo " Could not download specified DXVK version (${_dxvk_version})"
        echo ""
        echo "#######################################################"
        echo ""
        echo "Please select DXVK release version (ex: v1.6.1)"
        read -rp "> [latest]: " _dxvk_version
        echo ""
      fi
  done
}

function latest_mono {
  if [ "$_use_latest_mono" = "true" ]; then
    curl -s https://api.github.com/repos/madewokherd/wine-mono/releases/latest | grep "browser_download_url.*x86.tar.xz" | cut -d : -f 2,3 | tr -d \"
  else
    _current_mono=$( grep "#define MONO_VERSION" "$_wine_tkg_git_path/src/$_winesrcdir/dlls/appwiz.cpl/addons.c" | cut -d'"' -f 2 )
    echo "https://github.com/madewokherd/wine-mono/releases/download/wine-mono-$_current_mono/wine-mono-$_current_mono-x86.tar.xz"
  fi
}

function latest_mono_msi {
  if [ "$_use_latest_mono" = "true" ]; then
    curl -s https://api.github.com/repos/madewokherd/wine-mono/releases/latest | grep "browser_download_url.*x86.msi" | cut -d : -f 2,3 | tr -d \"
  else
    _current_mono=$( grep "#define MONO_VERSION" "$_wine_tkg_git_path/src/$_winesrcdir/dlls/appwiz.cpl/addons.c" | cut -d'"' -f 2 )
    echo "https://github.com/madewokherd/wine-mono/releases/download/wine-mono-$_current_mono/wine-mono-$_current_mono-x86.msi"
  fi
}

if [ "$1" = "clean" ]; then
  proton_tkg_uninstaller
elif [ "$1" = "build_vrclient" ]; then
  build_vrclient
elif [ "$1" = "build_lsteamclient" ]; then
  build_lsteamclient
elif [ "$1" = "build_vkd3d" ]; then
  build_vkd3d
elif [ "$1" = "build_dxvk" ]; then
  build_dxvk
elif [ "$1" = "build_mediaconv" ]; then
  _build_mediaconv="true" build_mediaconverter
elif [ "$1" = "build_steamhelper" ]; then
  build_steamhelper
else
  # If $1 contains a path, and it exists, use it as default for config
  if [ -n "$1" ]; then
    _EXT_CONFIG_PATH="$(readlink -m $1)"
    if [ ! -f "$_EXT_CONFIG_PATH" ]; then
      echo "User-supplied external config file '${_EXT_CONFIG_PATH}' not found! Please fix your passed path!"
      exit 0
    fi
    sed -i -e "s|_EXT_CONFIG_PATH.*|_EXT_CONFIG_PATH=${_EXT_CONFIG_PATH}|" "$_nowhere"/proton-tkg-profiles/advanced-customization.cfg
  fi

  rm -rf "$_nowhere"/proton_dist_tmp

  cd "$_nowhere"

  # We'll need a token to register to wine-tkg-git - keep one for us to steal wine-tkg-git options later
  echo -e "_proton_tkg_path='${_nowhere}'\n_no_steampath='${_no_steampath}'" > proton_tkg_token && cp proton_tkg_token "${_wine_tkg_git_path}/"

  echo -e "Proton-tkg - $(date +"%m-%d-%Y %H:%M:%S")" > "$_logdir"/proton-tkg.log

  if [ -n "$_runtime" ]; then
    rm -rf "${_nowhere}"/external-resources/steam-runtime
    if [ -d /tmp ]; then
      cp -R "$_runtime" /tmp/
      ln -s /tmp/steam-runtime "${_nowhere}"/external-resources/
    else
      mkdir -p "${_resources_path}"/steam-runtime
      cp -R "$_runtime" external-resources/
    fi
    rm -f steam-runtime/pinned_libs_32/*curl.so* # Use system curl libs for git
    rm -f steam-runtime/pinned_libs_64/*curl.so* # Use system curl libs for git
  fi

  # Now let's build
  cd "$_wine_tkg_git_path"
  if [ -e "/usr/bin/makepkg" ] && [ "$_nomakepkg" = "false" ]; then
    makepkg -s || true
  else
    rm -f "$_wine_tkg_git_path"/non-makepkg-builds/HL3_confirmed
    if [ -n "$_runtime" ]; then
      echo -e "Using Steam runtime\n"
      "$_nowhere"/steam-runtime/run.sh ./non-makepkg-build.sh
    else
      ./non-makepkg-build.sh
      # makepkg proton pkgver loop hack
      if [ "$_isfirstloop" = "true" ]; then
        exit 0
      fi
    fi
  fi

  # Wine-tkg-git has injected versioning and settings in the token for us, so get the values back
  source "$_nowhere/proton_tkg_token"

  if [ "$_NOLIB32" = "true" ]; then
    _lib32name="lib"
    _lib64name="lib"
  else
    _lib32name="lib"
    _lib64name="lib64"
  fi

  # Prompt to re-use existing gst
  if [ -d "${_resources_path}"/gst ] && [ -z $_reuse_built_gst ]; then
    echo "    Existing proton gstreamer dir found. Do you want to use it instead of rebuilding?"
    read -rp $'\n> Y/n : ' _reuse_gst;
    if ( [ "$_reuse_gst" != "n" ] && [ "$_reuse_gst" != "N" ] ); then
      _reuse_built_gst="true"
    fi
  fi

  # We might not want experimental branches since they are a moving target and not useful to us, so fallback to regular by default unless _proton_branch_exp="true" is passed
  if [[ "$_proton_branch" = experimental* ]] && [ "$_proton_branch_exp" != "true" ]; then
    echo -e "#### Replacing experimental branch by regular ####"
    sed -i "s/experimental_/proton_/g" "$_nowhere/proton_tkg_token" && source "$_nowhere/proton_tkg_token"
  fi

  # Use custom compiler paths if defined
  if [ -n "${CUSTOM_MINGW_PATH}" ] && [ -z "${CUSTOM_GCC_PATH}" ]; then
    PATH="${PATH}:${CUSTOM_MINGW_PATH}/bin:${CUSTOM_MINGW_PATH}/lib:${CUSTOM_MINGW_PATH}/include"
  elif [ -n "${CUSTOM_GCC_PATH}" ] && [ -z "${CUSTOM_MINGW_PATH}" ]; then
    PATH="${CUSTOM_GCC_PATH}/bin:${CUSTOM_GCC_PATH}/lib:${CUSTOM_GCC_PATH}/include:${PATH}"
  elif [ -n "${CUSTOM_MINGW_PATH}" ] && [ -n "${CUSTOM_GCC_PATH}" ]; then
    PATH="${CUSTOM_GCC_PATH}/bin:${CUSTOM_GCC_PATH}/lib:${CUSTOM_GCC_PATH}/include:${CUSTOM_MINGW_PATH}/bin:${CUSTOM_MINGW_PATH}/lib:${CUSTOM_MINGW_PATH}/include:${PATH}"
  fi

  # If mingw-w64 gcc can't be found, disable building vkd3d-proton
  if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo -e "######\nmingw-w64 gcc not found - vkd3d-proton and dxvk won't be built\n######"
    _build_vkd3d="false"
    if [ "$_use_dxvk" = "git" ]; then
      _use_dxvk="latest"
    fi
  else
    if [ "$_use_vkd3dlib" = "false" ]; then
      _build_vkd3d="true"
    fi
    echo -e "######\nmingw-w64 gcc found\n######"
  fi

  # Copy the resulting package in here to begin our work
  if [ -e "$_proton_pkgdest"/../HL3_confirmed ]; then

    cd "$_nowhere"

    # Create required dirs and clean
    if [ -z "$_protontkg_true_version" ]; then
      export _protontkg_true_version="$_protontkg_version"
    fi

    rm -rf "proton_tkg_$_protontkg_version" && mkdir "proton_tkg_$_protontkg_version"
    mkdir -p proton_template/share/fonts

    mv "$_proton_pkgdest" proton_dist_tmp

    # Liberation Fonts
    rm -f proton_template/share/fonts/*
    git clone https://github.com/liberationfonts/liberation-fonts.git || true # It'll complain the path already exists on subsequent builds
    cd liberation-fonts
    git reset --hard 9510ebd
    git clean -xdf
    #git pull
    patch -Np1 < "$_nowhere/proton_template/LiberationMono-Regular.patch"
    make -j$(nproc)
    cp -rv liberation-fonts-ttf*/Liberation{Sans-Regular,Sans-Bold,Serif-Regular,Mono-Regular}.ttf "$_nowhere/proton_template/share/fonts"/
    cd "$_nowhere"

    if [ "$_NUKR" != "debug" ]; then
      if [ -d Proton ] && [ ! -f Proton/proton ]; then
        ( cd Proton && find . -name . -o -prune -exec rm -rf -- {} + ) # We need to clean everything including dotfiles
      fi
      # Clone Proton tree as we need to build some tools from it
      git clone https://github.com/ValveSoftware/Proton || true # It'll complain the path already exists on subsequent builds
      cd Proton
      git reset --hard origin/HEAD
      git clean -xdf
      if ( ! git pull --ff-only ) || ( [ -n "$_bleeding_tag" ] ); then
        echo -e "######\nProton tree was force-pushed upstream.. Recloning clean to avoid issues..\n######"
        find . -name . -o -prune -exec rm -rf -- {} + # We need to clean everything including dotfiles
        cd ..
        git clone https://github.com/ValveSoftware/Proton || true # It'll complain the path already exists on subsequent builds
        cd Proton
      else
        git pull origin
      fi
      if [ -n "$_bleeding_tag" ]; then
        _bleeding_commit=$(git rev-list -n 1 "${_bleeding_tag}")
        _proton_branch="$_bleeding_commit"
      fi
      git checkout "$_proton_branch"

      _user_patches_no_confirm="true"
      _userpatch_target="proton"
      _userpatch_ext="myproton"
      proton_patcher
    else
      cd Proton
    fi

    # Embed fake data to spoof desired fonts
    fontforge -script "$_nowhere/Proton/fonts/scripts/generatefont.pe" "$_nowhere/proton_template/share/fonts/LiberationSans-Regular" "Arial" "Arial" "Arial"
    fontforge -script "$_nowhere/Proton/fonts/scripts/generatefont.pe" "$_nowhere/proton_template/share/fonts/LiberationSans-Bold" "Arial-Bold" "Arial" "Arial Bold"
    fontforge -script "$_nowhere/Proton/fonts/scripts/generatefont.pe" "$_nowhere/proton_template/share/fonts/LiberationSerif-Regular" "TimesNewRoman" "Times New Roman" "Times New Roman"
    fontforge -script "$_nowhere/Proton/fonts/scripts/generatefont.pe" "$_nowhere/proton_template/share/fonts/LiberationMono-Regular" "CourierNew" "Courier New" "Courier New"

    # Build GST/mediaconverter
    if [ "$_build_mediaconv" = "true" ] || [ "$_build_gstreamer" = "true" ]; then
      if [ "$_reuse_built_gst" = "true" ] && [ -d "${_resources_path}"/gst ]; then
        cp -r "${_resources_path}"/gst "$_nowhere"/gst
      else
        build_mediaconverter
        rm -rf "${_resources_path}"/gst && cp -r "$_nowhere"/gst "${_resources_path}"/gst
      fi
    fi

    # Grab share template and inject version
    _versionpre=`date '+%s'`
    echo "$_versionpre" "TKG-proton-$_protontkg_true_version" > "$_nowhere/proton_dist_tmp/version" && cp -r "$_nowhere/proton_template/share"/* "$_nowhere/proton_dist_tmp/share"/

    # Create the dxvk dirs
    mkdir -p "$_nowhere/proton_dist_tmp/lib64/wine/dxvk"
    mkdir -p "$_nowhere/proton_dist_tmp/lib/wine/dxvk"

    # Build vrclient libs
    # I'm not sure we actually need this considering VR support is broken, but it might be needed by other tools
    if [ "$_steamvr_support" = "true" ]; then
      build_vrclient
      cd Proton
    fi

    # Build lsteamclient libs
    build_lsteamclient

    # Build steam helper
    build_steamhelper

    # gst/mediaconverter
    # Disable lib32 stuff when _NOLIB32 is enabled
    if [ "$_NOLIB32" = "true" ]; then
      _lib32_gstreamer="false"
      _use_lib32_mpeg2dec_and_x264="false"
    fi
    if [ "$_build_mediaconv" = "true" ] || [ "$_build_gstreamer" = "true" ]; then
      mv "$_nowhere"/gst/lib64/* proton_dist_tmp/$_lib64name/
      if [ "$_lib32_gstreamer" = "true" ]; then
        mv "$_nowhere"/gst/lib/* proton_dist_tmp/$_lib32name/
      fi
    fi
    rm -rf "$_nowhere/gst"

    # vkd3d
    # Build vkd3d-proton when vkd3dlib is disabled - Requires MinGW-w64-gcc or it won't be built
    if [ "$_build_vkd3d" = "true" ]; then
      build_vkd3d
      mkdir -p proton_dist_tmp/lib64/wine/vkd3d-proton
      mkdir -p proton_dist_tmp/lib/wine/vkd3d-proton
      cp -v "$_nowhere"/vkd3d-proton/build/lib64-vkd3d/bin/* proton_dist_tmp/lib64/wine/vkd3d-proton/
      cp -v "$_nowhere"/vkd3d-proton/build/lib32-vkd3d/bin/* proton_dist_tmp/lib/wine/vkd3d-proton/
    fi

    # dxvk
    _proton_dxvk_path32="proton_dist_tmp/lib/wine/dxvk/"
    _proton_dxvk_path64="proton_dist_tmp/lib64/wine/dxvk/"
    cd "$_nowhere"
    if [ "$_use_dxvk" != "false" ]; then
      if [ "$_use_dxvk" = "git" ]; then
        build_dxvk
      elif ( [ ! -d "$_nowhere"/dxvk ] && [ ! -e "$_nowhere"/dxvk ] ) || [ "$_use_dxvk" = "release" ] || [ "$_use_dxvk" = "latest" ]; then
        rm -rf "$_nowhere"/dxvk
        if [ "$_use_dxvk" = "latest" ]; then
          # Download it & extract it into a temporary folder so we don't mess up the build in case proton-tkg also has/will have a folder "$_nowhere"/build (that folder is in the artifact zip)
          rm -rf "$_nowhere"/tmp-dxvk-artifact
          mkdir "$_nowhere"/tmp-dxvk-artifact
          cd "$_nowhere"/tmp-dxvk-artifact
          download_dxvk_version
          unzip dxvk-latest-artifact.zip >/dev/null 2>&1
          rm -f dxvk-latest-artifact.zip
          mv "$_nowhere"/tmp-dxvk-artifact/build/dxvk-* "$_nowhere"/dxvk
          cd "$_nowhere"
          rm -rf "$_nowhere"/tmp-dxvk-artifact
        else
          download_dxvk_version
          tar -xvf dxvk-*.tar.gz >/dev/null 2>&1
          rm -f dxvk-*.tar.*
          mv "$_nowhere"/dxvk-*.* "$_nowhere"/dxvk
        fi
      fi
      chmod -R 755 "$_nowhere"/dxvk
      # Remove d3d10.dll and d3d10_1.dll when using a 5.3 base or newer - https://github.com/doitsujin/dxvk/releases/tag/v1.6
      if [ "$_dxvk_minimald3d10" = "true" ]; then
        cp -v dxvk/x64/{d3d10core.dll,d3d11.dll,d3d9.dll,dxgi.dll} $_proton_dxvk_path64
        cp -v dxvk/x32/{d3d10core.dll,d3d11.dll,d3d9.dll,dxgi.dll} $_proton_dxvk_path32
      else
        cp -v dxvk/x64/{d3d10.dll,d3d10_1.dll,d3d10core.dll,d3d11.dll,d3d9.dll,dxgi.dll} $_proton_dxvk_path64
        cp -v dxvk/x32/{d3d10.dll,d3d10_1.dll,d3d10core.dll,d3d11.dll,d3d9.dll,dxgi.dll} $_proton_dxvk_path32
      fi
      if [ -e dxvk/x64/dxvk_config.dll ]; then
        cp -v dxvk/x64/dxvk_config.dll $_proton_dxvk_path64
      fi
      if [ -e dxvk/x32/dxvk_config.dll ]; then
        cp -v dxvk/x32/dxvk_config.dll $_proton_dxvk_path32
      fi
    fi

    if [ "$_proton_nvapi_disable" != "true" ]; then
      build_dxvk_nvapi
      mkdir -p "$_nowhere"/proton_dist_tmp/lib64/wine/nvapi
      mkdir -p "$_nowhere"/proton_dist_tmp/lib/wine/nvapi
      cp -v "$_nowhere"/Proton/build/dxvk-nvapi-master/x64/* "$_nowhere"/proton_dist_tmp/lib64/wine/nvapi
      cp -v "$_nowhere"/Proton/build/dxvk-nvapi-master/x32/* "$_nowhere"/proton_dist_tmp/lib/wine/nvapi
    fi

    echo ''
    echo "Injecting wine-mono & wine-gecko..."

    # mono
    mkdir -p "$_nowhere"/mono && cd "$_nowhere"/mono
    rm -rf "$_nowhere"/mono/*
    _mono_bin=$( latest_mono )
    if [ ! -e ${_mono_bin##*/} ]; then
      latest_mono | wget -qi -
    fi
    #_mono_msi=$( latest_mono_msi )
    #if [ ! -e ${_mono_msi##*/} ]; then
    #  latest_mono_msi | wget -qi -
    #fi
    cd "$_nowhere"
    mkdir -p proton_dist_tmp/share/wine/mono
    tar -xvJf "$_nowhere"/mono/wine-mono-*.tar.xz -C proton_dist_tmp/share/wine/mono >/dev/null 2>&1
    #mv "$_nowhere"/mono/wine-mono-*.msi proton_dist_tmp/share/wine/mono

    # gecko
    _gecko_ver="2.47.2"
    _gecko_compression=".tar.xz"
    mkdir -p "$_nowhere"/gecko && cd "$_nowhere"/gecko
    if [ ! -e "wine-gecko-$_gecko_ver-x86_64$_gecko_compression" ]; then
      wget https://dl.winehq.org/wine/wine-gecko/$_gecko_ver/wine-gecko-$_gecko_ver-x86_64$_gecko_compression
    fi
    if [ ! -e "wine-gecko-$_gecko_ver-x86$_gecko_compression" ]; then
      wget https://dl.winehq.org/wine/wine-gecko/$_gecko_ver/wine-gecko-$_gecko_ver-x86$_gecko_compression
    fi
    cd "$_nowhere"
    mkdir -p proton_dist_tmp/share/wine/gecko
    tar -xvf "$_nowhere"/gecko/wine-gecko-$_gecko_ver-x86_64$_gecko_compression -C proton_dist_tmp/share/wine/gecko >/dev/null 2>&1
    tar -xvf "$_nowhere"/gecko/wine-gecko-$_gecko_ver-x86$_gecko_compression -C proton_dist_tmp/share/wine/gecko >/dev/null 2>&1

    # Move prepared dist
    mv "$_nowhere"/proton_dist_tmp "$_nowhere"/"proton_tkg_$_protontkg_version"/files && cd "$_nowhere"

    # Grab conf template and inject version
    echo "$_versionpre" "TKG-proton-$_protontkg_true_version" > "proton_tkg_$_protontkg_version/version" && cp "proton_template/conf"/* "proton_tkg_$_protontkg_version"/ && sed -i -e "s|TKGVERSION|$_protontkg_version|" "proton_tkg_$_protontkg_version/compatibilitytool.vdf"

    # Inject toolmanifest
    if [ "$_built_with_runtime" = "true" ]; then
      if [ -e "$_nowhere"/Proton/toolmanifest_runtime.vdf ] && [ "$_nosteamruntime" = "sniper" ]; then
        rm -f "proton_tkg_$_protontkg_version"/toolmanifest.vdf && cp "$_nowhere"/Proton/toolmanifest_runtime.vdf "proton_tkg_$_protontkg_version"/toolmanifest.vdf
        sed -i -e "s/1391110/1628350/g" "proton_tkg_$_protontkg_version"/toolmanifest.vdf
      elif [ -e "$_nowhere"/Proton/toolmanifest_runtime.vdf ] && [ "$_nosteamruntime" != "true" ]; then
        rm -f "proton_tkg_$_protontkg_version"/toolmanifest.vdf && cp "$_nowhere"/Proton/toolmanifest_runtime.vdf "proton_tkg_$_protontkg_version"/toolmanifest.vdf
      elif [ -e "$_nowhere"/Proton/toolmanifest_noruntime.vdf ] && [ "$_nosteamruntime" = "true" ]; then
        rm -f "proton_tkg_$_protontkg_version"/toolmanifest.vdf && cp "$_nowhere"/Proton/toolmanifest_noruntime.vdf "proton_tkg_$_protontkg_version"/toolmanifest.vdf
      fi
    elif [ -e "$_nowhere"/Proton/toolmanifest_noruntime.vdf ]; then
      rm -f "proton_tkg_$_protontkg_version"/toolmanifest.vdf && cp "$_nowhere"/Proton/toolmanifest_noruntime.vdf "proton_tkg_$_protontkg_version"/toolmanifest.vdf
    fi

    # steampipe fixups
    cp "$_nowhere"/proton_template/steampipe_fixups.py "$_nowhere"/"proton_tkg_$_protontkg_version"/

    # Inject current wine tree prefix version value in a proton-friendly format - major.minor-commitnumber
    _prefix_version=$( echo ${_protontkg_true_version} | sed 's/rc[0-9]//g; s/.r/-/; s/.[^.]*//4g; s/\.[^.*-]*//2g;' )
    if [[ "$_prefix_version" = *.*-* ]]; then
      sed -i -e "s|CURRENT_PREFIX_VERSION=\"TKG\"|CURRENT_PREFIX_VERSION=\"$_prefix_version\"|" "proton_tkg_$_protontkg_version/proton"
    else
      _prefix_version=$( echo "$_proton_branch" | egrep -o '[0-9].[0-9]' )
      sed -i -e "s|CURRENT_PREFIX_VERSION=\"TKG\"|CURRENT_PREFIX_VERSION=\"$_prefix_version-999\"|" "proton_tkg_$_protontkg_version/proton"
    fi

    #### Disable VR support patch as our wine-side support reportedly doesn't work
    # Patch our proton script to allow for VR support
    #if [ "$_steamvr_support" = "true" ]; then
    #  cd "$_nowhere/proton_tkg_$_protontkg_version"
    #  _patchname="vr-support.patch"
    #  echo -e "\nApplying $_patchname"
    #  patch -Np1 < "$_nowhere/proton_template/$_patchname" || exit 1
    #  cd "$_nowhere"
    #fi

    # Patch our proton script to handle minimal d3d10 implementation for dxvk on Wine 5.3+
    if [ "$_dxvk_minimald3d10" = "true" ]; then
      cd "$_nowhere/proton_tkg_$_protontkg_version"
      _patchname="dxvk_minimald3d10.patch"
      echo -e "\nApplying $_patchname"
      patch -Np1 < "$_nowhere/proton_template/$_patchname" || exit 1
      cd "$_nowhere"
      # Patch our proton script to handle dxvk_config lib
      if [ -e "$_nowhere"/dxvk/x64/dxvk_config.dll ]; then
        cd "$_nowhere/proton_tkg_$_protontkg_version"
        _patchname="dxvk_config_support.patch"
        echo -e "\nApplying $_patchname"
        patch -Np1 < "$_nowhere/proton_template/$_patchname" || exit 1
        cd "$_nowhere"
      fi
    fi

    # Patch our makepkg version of the proton script to not create default prefix and use /tmp/dist.lock
    if [ "$_ispkgbuild" = "true" ]; then
      cd "$_nowhere/proton_tkg_$_protontkg_version"
      _patchname="makepkg_adjustments.patch"
      echo -e "\nApplying $_patchname"
      patch -Np1 < "$_nowhere/proton_template/$_patchname" || exit 1
      cd "$_nowhere"
    fi

    # Patch our proton script to remove mfplay dll override when _proton_mf_hacks is disabled
    if [ "$_proton_mf_hacks" != "true" ]; then
      echo -e "\nUsing prebuilt mfplay"
      sed -i '/.*#disable built-in mfplay.*/d' "proton_tkg_$_protontkg_version/proton"
    fi

    if [ "$_new_lib_paths" = "true" ]; then
      cd "$_nowhere/proton_tkg_$_protontkg_version"
      _patchname="new_lib_paths.patch"
      echo -e "\nApplying $_patchname"
      patch -Np1 < "$_nowhere/proton_template/$_patchname" || exit 1
      cd "$_nowhere"
    fi

    rm -f "$_nowhere/proton_tkg_$_protontkg_version/proton.orig"

    # Set Proton-tkg user_settings.py defaults
    if [ "$_proton_nvapi_disable" = "true" ]; then
      sed -i 's/.*PROTON_NVAPI_DISABLE.*/     "PROTON_NVAPI_DISABLE": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    else
      sed -i 's/.*PROTON_NVAPI_DISABLE.*/#     "PROTON_NVAPI_DISABLE": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ "$_proton_winedbg_disable" = "true" ]; then
      sed -i 's/.*PROTON_WINEDBG_DISABLE.*/     "PROTON_WINEDBG_DISABLE": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    else
      sed -i 's/.*PROTON_WINEDBG_DISABLE.*/#     "PROTON_WINEDBG_DISABLE": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ "$_proton_conhost_disable" = "true" ]; then
      sed -i 's/.*PROTON_CONHOST_DISABLE.*/     "PROTON_CONHOST_DISABLE": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    else
      sed -i 's/.*PROTON_CONHOST_DISABLE.*/#     "PROTON_CONHOST_DISABLE": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ "$_proton_force_LAA" = "true" ]; then
      sed -i 's/.*PROTON_DISABLE_LARGE_ADDRESS_AWARE.*/#     "PROTON_DISABLE_LARGE_ADDRESS_AWARE": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    else
      sed -i 's/.*PROTON_DISABLE_LARGE_ADDRESS_AWARE.*/     "PROTON_DISABLE_LARGE_ADDRESS_AWARE": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ "$_proton_pulse_lowlat" = "true" ]; then
      sed -i 's/.*PROTON_PULSE_LOWLATENCY.*/     "PROTON_PULSE_LOWLATENCY": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    else
      sed -i 's/.*PROTON_PULSE_LOWLATENCY.*/#     "PROTON_PULSE_LOWLATENCY": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ "$_proton_dxvk_async" = "true" ]; then
      sed -i 's/.*PROTON_DXVK_ASYNC.*/     "PROTON_DXVK_ASYNC": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    else
      sed -i 's/.*PROTON_DXVK_ASYNC.*/#     "PROTON_DXVK_ASYNC": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ "$_proton_winetricks" = "true" ]; then
      sed -i 's/.*PROTON_WINETRICKS.*/     "PROTON_WINETRICKS": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    else
      sed -i 's/.*PROTON_WINETRICKS.*/#     "PROTON_WINETRICKS": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ -n "$_proton_dxvk_configfile" ]; then
      sed -i "s|.*DXVK_CONFIG_FILE.*|     \"DXVK_CONFIG_FILE\": \"${_proton_dxvk_configfile}\",|g" "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ -n "$_proton_dxvk_hud" ]; then
      sed -i "s|.*DXVK_HUD.*|     \"DXVK_HUD\": \"${_proton_dxvk_hud}\",|g" "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ "$_use_dxvk" != "false" ] && [ "$_dxvk_dxgi" != "true" ]; then
      sed -i 's/.*PROTON_USE_WINE_DXGI.*/     "PROTON_USE_WINE_DXGI": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi
    if [ -n "$_proton_shadercache_path" ]; then
      sed -i "s|.*PROTON_BYPASS_SHADERCACHE_PATH.*|     \"PROTON_BYPASS_SHADERCACHE_PATH\": \"${_proton_shadercache_path}\",|g" "proton_tkg_$_protontkg_version/user_settings.py"
    fi

    # Use the corresponding DXVK/D9VK combo options
    if [ "$_use_dxvk" != "false" ]; then
      sed -i 's/.*PROTON_USE_WINED3D11.*/#     "PROTON_USE_WINED3D11": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
      sed -i 's/.*PROTON_USE_WINED3D9.*/#     "PROTON_USE_WINED3D9": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    else
      sed -i 's/.*PROTON_USE_WINED3D11.*/     "PROTON_USE_WINED3D11": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
      sed -i 's/.*PROTON_USE_WINED3D9.*/     "PROTON_USE_WINED3D9": "1",/g' "proton_tkg_$_protontkg_version/user_settings.py"
    fi

    # Only use our local gstreamer when _build_gstreamer is enabled
    if [ "$_build_gstreamer" = "true" ]; then
      sed -i 's/"GST_PLUGIN_PATH_1_0"/"GST_PLUGIN_SYSTEM_PATH_1_0"/g' "proton_tkg_$_protontkg_version/proton"
    fi

    _standalone_start_vercheck=$( echo "$_protontkg_true_version" | cut -f1,2 -d'.' | sed 's/rc[0-9]//g;')
    echo -e "Full version: $_protontkg_true_version\nStripped version: ${_standalone_start_vercheck//./}" >> "$_logdir"/proton-tkg.log

    # Cleanup
    find "$_nowhere"/"proton_tkg_$_protontkg_version"/ -type f '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.def' -or -iname '*.debug' ')' -delete

    # pefixup
    if [ "$_unfrog" = "true" ] || ( [[ $_proton_branch != *3.* ]] && [[ $_proton_branch != *4.* ]] && [[ $_proton_branch != *5.* ]] && [ ${_standalone_start_vercheck//./} -ge 66 ] ); then
      echo ''
      echo "Fixing x86_64 PE files..."
      ( cd "$_nowhere/proton_tkg_$_protontkg_version/files/$_x86_64_windows_tail"
      if [ "$_pkg_strip" = "true" ]; then
        if [ "$_pefixup" = "objcopy" ]; then
          find -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.conf' ')' -printf '--strip-debug\0%p\0%p\0' | xargs -0 -r -P1 -n3 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
        else
          find -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.conf' ')' -printf '--strip-debug\0%p\0%p\0' | xargs -0 -r -P1 -n3 objcopy --file-alignment=4096
        fi
      fi
      if [ "$_pefixup" = "py" ]; then
        find -type f -name "*.dll" -printf "%p\0" | xargs -0 -r -P8 -n1 "$_nowhere/proton_template/pefixup.py"
        find -type f -name "*.drv" -printf "%p\0" | xargs -0 -r -P8 -n1 "$_nowhere/proton_template/pefixup.py"
      fi
      )
      echo "Fixing i386 PE files..."
      ( cd "$_nowhere/proton_tkg_$_protontkg_version/files/$_i386_windows_tail"
      if [ "$_pkg_strip" = "true" ]; then
        if [ "$_pefixup" = "objcopy" ]; then
          find -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.conf' ')' -printf '--strip-debug\0%p\0%p\0' | xargs -0 -r -P1 -n3 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
        else
          find -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.conf' ')' -printf '--strip-debug\0%p\0%p\0' | xargs -0 -r -P1 -n3 objcopy --file-alignment=4096
        fi
      fi
      if [ "$_pefixup" = "py" ]; then
        find -type f -name "*.dll" -printf "%p\0" | xargs -0 -r -P8 -n1 "$_nowhere/proton_template/pefixup.py"
        find -type f -name "*.drv" -printf "%p\0" | xargs -0 -r -P8 -n1 "$_nowhere/proton_template/pefixup.py"
      fi
      )
    fi

    # perms
    find "$_nowhere/proton_tkg_$_protontkg_version"/files/lib/wine -type f -execdir chmod a-w '{}' '+'
    find "$_nowhere/proton_tkg_$_protontkg_version"/files/lib64/wine -type f -execdir chmod a-w '{}' '+'

    cd "$_nowhere"

    # Remove gst-editing-services on pacman distros
    if [ -e /usr/bin/pacman ]; then
      if pacman -Qq gst-editing-services &> /dev/null; then
        echo '! found gst-editing-services package, known to break wine prefix creation !'
        read -rp "  Uninstall it?"$'\n> N/y : ' _gst_editing_services;
        if [[ "$_gst_editing_services" =~ [yY] ]]; then
          sudo pacman -R gst-editing-services
        fi
      fi
    fi

    # default prefix
    echo ''
    echo "Generating default prefix..."
    python3 "$_nowhere"/proton_template/default_pfx.py "$_nowhere/proton_tkg_$_protontkg_version/files/share/default_pfx" "$_nowhere/proton_tkg_$_protontkg_version/files" >>"$_logdir"/proton-tkg.log 2>&1

    wine_is_running

    # Enable standalone start when the steamhelper is disabled
    if [ "$_proton_use_steamhelper" != "true" ]; then
      sed -i 's/.*PROTON_STANDALONE_START.*/     "PROTON_STANDALONE_START": "1",/g' "$_nowhere/proton_tkg_$_protontkg_version/user_settings.py" | echo "Enable standalone start" >> "$_logdir"/proton-tkg.log
    fi

    # steampipe fixups
    echo ''
    echo "Running steampipe fixups..."
    python3 "$_nowhere"/proton_template/steampipe_fixups.py process "$_nowhere"/"proton_tkg_$_protontkg_version"

    if [ "$_ispkgbuild" != "true" ]; then
      if [ "$_no_steampath" != "y" ]; then
        if [ "$_no_autoinstall" != "true" ] ; then
          steam_is_running

          # Create custom compat tools dir if needed
          mkdir -p "$_steampath/compatibilitytools.d"

          # Nuke same version if exists before copying new build
          if [ -d "$_steampath/compatibilitytools.d/proton_tkg_$_protontkg_version" ]; then
            rm -rf "$_steampath/compatibilitytools.d/proton_tkg_$_protontkg_version"
          fi

          # Get rid of the token
          rm -f proton_tkg_token

          mv "proton_tkg_$_protontkg_version" "$_steampath/compatibilitytools.d"/ && echo "" &&
          echo "####################################################################################################"
          echo ""
          echo " Proton-tkg build installed to $_steampath/compatibilitytools.d/proton_tkg_$_protontkg_version"
          echo ""
          echo "####################################################################################################"
          if [ "$_skip_uninstaller" != "true" ]; then
            _just_built="proton_tkg_$_protontkg_version"
            echo ""
            read -rp "Do you want to run the uninstaller to remove previous/superfluous builds? N/y: " _ask_uninstall;
            if [[ "$_ask_uninstall" =~ [yY] ]]; then
              proton_tkg_uninstaller
            fi
          fi
        fi
      else
        # Get rid of the token
        rm -f proton_tkg_token
        mkdir -p "$_nowhere"/built && mv "proton_tkg_$_protontkg_version" "$_nowhere/built/" && echo "" &&
        echo "####################################################################################################"
        echo ""
        echo " Your Proton-tkg build is now available in $_nowhere/built/proton_tkg_$_protontkg_version"
        echo ""
        echo "####################################################################################################"
        if [ -e "$_nowhere"/tarplz ];then
          ( cd "$_nowhere"/built && tar -cvf "proton_tkg_$_protontkg_version".tar "proton_tkg_$_protontkg_version" && rm -rf "proton_tkg_$_protontkg_version" )
        fi
      fi
    else
      # Apparently this can happen.. So let's clean it up if needed.
      if [[ -f /usr/share/steam/compatibilitytools.d/proton_tkg_makepkg/dist* ]] || [[ -d /usr/share/steam/compatibilitytools.d/proton_tkg_makepkg/dist* ]]; then
        echo -e "\nAn undesirable remnant of a previous build using /dist was found. We need to remove it from /usr/share/steam/compatibilitytools.d with sudo."
        sudo sh -c 'rm -rf /usr/share/steam/compatibilitytools.d/proton_tkg_makepkg/dist*'
      fi
    fi
  else
    rm "$_nowhere"/proton_tkg_token
    echo "The required initial proton_dist build is missing! Wine-tkg-git compilation may have failed."
  fi
fi
