#!/bin/bash

# Created by: Tk-Glitch <ti3nou at gmail dot com>

# This script creates Steamplay compatible wine builds based on wine-tkg-git and additional proton patches and libraries.
# It is not standalone and can be considered an addon to wine-tkg-git PKGBUILD and patchsets.

# You can use the uninstall feature by calling the script with "clean" as argument : ./proton-tkg.sh clean
# You can run the vrclient building alone with : ./proton-tkg.sh build_vrclient
# You can run the lsteamclient building alone with : ./proton-tkg.sh build_lsteamclient
# You can run the steamhelper building alone with : ./proton-tkg.sh build_steamhelper

set -e

_nowhere="$PWD"
_nomakepkg="true"
_no_steampath="false"

# Build vkd3d - Requires Wine installed system-wide
_build_vkd3d="false"

# Enforce using makepkg when using --makepkg
if [ "$1" = "--makepkg" ]; then
  _nomakepkg="false"
fi

if [ "$_ispkgbuild" = "true" ]; then
  _wine_tkg_git_path="${_nowhere}/../../wine-tkg-git"
else
  _wine_tkg_git_path="${_nowhere}/../wine-tkg-git" # Change to wine-tkg-git path if needed

  # Set Steam root path
  if [ -d "$HOME/.steam/root" ]; then # typical on Arch
    _steampath="$HOME/.steam/root"
  elif [ -e "$HOME/.steam/steam.sh" ]; then # typical on Ubuntu
    _steampath="$HOME/.steam"
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

function build_vrclient {
  cd "$_nowhere"/Proton
  git clone https://github.com/ValveSoftware/openvr.git || true # It'll complain the path already exists on subsequent builds
  cd openvr
  git reset --hard HEAD
  git clean -xdf
  git pull origin master
  #git checkout 52065df3d6f3af96300dac98cdf7397f26abfcd7
  cd ..

  export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls --nomsvcrt --dll -I$_nowhere/proton_dist_tmp/include/wine/windows/ -I$_nowhere/proton_dist_tmp/include/ -I$_nowhere/proton_dist_tmp/include/wine/"
  export CFLAGS="-O2 -g"
  export CXXFLAGS="-Wno-attributes -std=c++0x -O2 -g"
  PATH="$_nowhere"/proton_dist_tmp/bin:$PATH
  if [ "$_standard_dlopen" = "true" ]; then
    patch -Np1 < "$_nowhere/proton_template/vrclient-use_standard_dlopen_instead_of_the_libwine_wrappers.patch"
    _cxx_addon+=" -ldl"
  fi

  rm -rf build/vrclient.win64
  rm -rf build/vrclient.win32
  mkdir -p build/vrclient.win64
  mkdir -p build/vrclient.win32

  cp -a vrclient_x64/* build/vrclient.win64
  cp -a vrclient_x64/* build/vrclient.win32 && mv build/vrclient.win32/vrclient_x64 build/vrclient.win32/vrclient && mv build/vrclient.win32/vrclient/vrclient_x64.spec build/vrclient.win32/vrclient/vrclient.spec

  cd build/vrclient.win64
  winemaker $WINEMAKERFLAGS -L"$_nowhere/proton_dist_tmp/lib64/" -L"$_nowhere/proton_dist_tmp/lib64/wine/" -I"$_nowhere/Proton/build/vrclient.win64/vrclient_x64/" -I"$_nowhere/Proton/build/vrclient.win64/" vrclient_x64
  make -e CC="winegcc -m64" CXX="wineg++ -m64 $_cxx_addon" -C "$_nowhere/Proton/build/vrclient.win64/vrclient_x64" -j$(nproc) && strip vrclient_x64/vrclient_x64.dll.so
  winebuild --dll --fake-module -E "$_nowhere/Proton/build/vrclient.win64/vrclient_x64/vrclient_x64.spec" -o vrclient_x64.dll.fake
  cd ../..

  cd build/vrclient.win32
  winemaker $WINEMAKERFLAGS --wine32 -L"$_nowhere/proton_dist_tmp/lib/" -L"$_nowhere/proton_dist_tmp/lib/wine/" -I"$_nowhere/Proton/build/vrclient.win32/vrclient/" -I"$_nowhere/Proton/build/vrclient.win32/" vrclient
  make -e CC="winegcc -m32" CXX="wineg++ -m32 $_cxx_addon" -C "$_nowhere/Proton/build/vrclient.win32/vrclient" -j$(nproc) && strip vrclient/vrclient.dll.so
  winebuild --dll --fake-module -E "$_nowhere/Proton/build/vrclient.win32/vrclient/vrclient.spec" -o vrclient.dll.fake
  cd $_nowhere

  # Inject vrclient & openvr libs in our wine-tkg-git build
  cp -v Proton/build/vrclient.win64/vrclient_x64/vrclient_x64.dll.so proton_dist_tmp/lib64/wine/ && cp -v Proton/build/vrclient.win64/vrclient_x64.dll.fake proton_dist_tmp/lib64/wine/fakedlls/vrclient_x64.dll
  cp -v Proton/build/vrclient.win32/vrclient/vrclient.dll.so proton_dist_tmp/lib/wine/ && cp -v Proton/build/vrclient.win32/vrclient.dll.fake proton_dist_tmp/lib/wine/fakedlls/vrclient.dll

  cp -v Proton/openvr/bin/win32/openvr_api.dll proton_dist_tmp/lib/wine/dxvk/openvr_api_dxvk.dll
  cp -v Proton/openvr/bin/win64/openvr_api.dll proton_dist_tmp/lib64/wine/dxvk/openvr_api_dxvk.dll
}

function build_lsteamclient {
  cd "$_nowhere"/Proton
  export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls --nomsvcrt --dll -I$_nowhere/proton_dist_tmp/include/wine/windows/ -I$_nowhere/proton_dist_tmp/include/ -I$_wine_tkg_git_path/src/$_winesrcdir/include/"
  export CFLAGS="-O2 -g"
  export CXXFLAGS="-fpermissive -Wno-attributes -O2 -g"
  export PATH="$_nowhere"/proton_dist_tmp/bin:$PATH
  if [[ "$_proton_branch" != proton_3.* ]] && [[ "$_proton_branch" != proton_4.* ]]; then
    _cxx_addon="-std=gnu++11"
    if [ "$_standard_dlopen" = "true" ]; then
      patch -Np1 < "$_nowhere/proton_template/steamclient-use_standard_dlopen_instead_of_the_libwine_wrappers.patch"
      _cxx_addon+=" -ldl"
    fi
  fi

  rm -rf build/lsteamclient.win64
  rm -rf build/lsteamclient.win32
  mkdir -p build/lsteamclient.win64
  mkdir -p build/lsteamclient.win32

  cp -a lsteamclient/* build/lsteamclient.win64
  cp -a lsteamclient/* build/lsteamclient.win32

  cd build/lsteamclient.win64
  winemaker $WINEMAKERFLAGS -DSTEAM_API_EXPORTS -L"$_nowhere/proton_dist_tmp/lib64/" -L"$_nowhere/proton_dist_tmp/lib64/wine/" .
  make -e CC="winegcc -m64" CXX="wineg++ -m64 $_cxx_addon" -C "$_nowhere/Proton/build/lsteamclient.win64" -j$(nproc) && strip lsteamclient.dll.so
  cd ../..

  cd build/lsteamclient.win32
  winemaker $WINEMAKERFLAGS --wine32 -DSTEAM_API_EXPORTS -L"$_nowhere/proton_dist_tmp/lib/" -L"$_nowhere/proton_dist_tmp/lib/wine/" .
  make -e CC="winegcc -m32" CXX="wineg++ -m32 $_cxx_addon" -C "$_nowhere/Proton/build/lsteamclient.win32" -j$(nproc) && strip lsteamclient.dll.so
  cd $_nowhere

  # Inject lsteamclient libs in our wine-tkg-git build
  cp -v Proton/build/lsteamclient.win64/lsteamclient.dll.so proton_dist_tmp/lib64/wine/
  cp -v Proton/build/lsteamclient.win32/lsteamclient.dll.so proton_dist_tmp/lib/wine/
}

function build_vkd3d {
  cd "$_nowhere"
  mkdir -p vkd3d-fork-build && cd vkd3d-fork-build
  git clone https://github.com/HansKristian-Work/vkd3d.git || true # It'll complain the path already exists on subsequent builds
  cd vkd3d
  git reset --hard HEAD
  git clean -xdf
  git pull origin master
  ./autogen.sh
  cd ..

  export CFLAGS="-O2 -g -I$_wine_tkg_git_path/src/$_winesrcdir/include/"
  export CXXFLAGS="-Wno-attributes -O2 -g -I$_wine_tkg_git_path/src/$_winesrcdir/include/"
  export PATH="$_nowhere"/proton_dist_tmp/bin:$PATH

  rm -rf build/lib64-vkd3d
  rm -rf build/lib32-vkd3d
  mkdir -p build/lib64-vkd3d/out
  mkdir -p build/lib32-vkd3d/out

  export CC='gcc -m64'
  export CXX='g++ -m64'
  cd build/lib64-vkd3d
  "$_nowhere"/vkd3d-fork-build/vkd3d/configure --prefix="$_nowhere/vkd3d-fork-build/build/lib64-vkd3d/out" --with-spirv-tools
  make -j$(nproc) -C "$_nowhere/vkd3d-fork-build/build/lib64-vkd3d" && make install
  cd ../..

  export CC='gcc -m32'
  export CXX='g++ -m32'
  cd build/lib32-vkd3d
  "$_nowhere"/vkd3d-fork-build/vkd3d/configure --prefix="$_nowhere/vkd3d-fork-build/build/lib32-vkd3d/out" --with-spirv-tools
  make -j$(nproc) -C "$_nowhere/vkd3d-fork-build/build/lib32-vkd3d" && make install
  cd $_nowhere
}

function build_steamhelper {
  if [[ $_proton_branch != proton_3.* ]]; then
    rm -rf Proton/build/steam.win32
    mkdir -p Proton/build/steam.win32
    cp -a Proton/steam_helper/* Proton/build/steam.win32
    cd Proton/build/steam.win32

    if [ "$_proton_branch" = "proton_4.2" ] || [ "$_proton_branch" = "proton_5.0" ]; then
      export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls --nomsvcrt --wine32 -I$_nowhere/proton_dist_tmp/include/wine/windows/ -I$_nowhere/proton_dist_tmp/include/ -L$_nowhere/proton_dist_tmp/lib/ -L$_nowhere/proton_dist_tmp/lib/wine/"
    else
      export WINEMAKERFLAGS="--nosource-fix --nolower-include --nodlls --wine32 -I$_nowhere/proton_dist_tmp/include/wine/windows/ -I$_nowhere/proton_dist_tmp/include/wine/msvcrt/ -I$_nowhere/proton_dist_tmp/include/ -L$_nowhere/proton_dist_tmp/lib/ -L$_nowhere/proton_dist_tmp/lib/wine/"
    fi

    winemaker $WINEMAKERFLAGS --guiexe -lsteam_api -lole32 -I"$_nowhere/Proton/build/lsteamclient.win32/steamworks_sdk_142/" -L"$_nowhere/Proton/steam_helper" .
    make -e CC="winegcc -m32" CXX="wineg++ -m32" -C "$_nowhere/Proton/build/steam.win32" -j$(nproc) && strip steam.exe.so
    cd $_nowhere

    # Inject steam helper winelib and libsteam_api lib in our wine-tkg-git build
    cp -v Proton/build/steam.win32/steam.exe.so proton_dist_tmp/lib/wine/
    cp -v Proton/build/steam.win32/libsteam_api.so proton_dist_tmp/lib/
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
	  if [ "$_CONDITION" = "y" ] || [ "$_user_patches_no_confirm" = "true" ]; then
	    for _f in "${_patches[@]}"; do
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
	if [ ${#_patches[@]} -ge 2 ] || [ -e "${_patches}" ]; then
	  if [ "$_user_patches_no_confirm" != "true" ]; then
	    echo "Found ${#_patches[@]} userpatches for ${_userpatch_target}:"
	    printf '%s\n' "${_patches[@]}"
	    read -rp "Do you want to install it/them? - Be careful with that ;)"$'\n> N/y : ' _CONDITION;
	  fi
	  if [ "$_CONDITION" = "y" ] || [ "$_user_patches_no_confirm" = "true" ]; then
	    for _f in "${_patches[@]}"; do
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

    cp $_config_file $_config_file.bak && echo "Your config.vdf file was backed up from $_config_file (.bak)" && echo ""

    echo "What Proton-tkg build do you want to uninstall?"

    i=1
    for build in ${_strip_builds[@]}; do
      echo "  $i - $build" && ((i+=1))
    done

    read -rp "choice [1-$(($i-1))]: " _to_uninstall;

    i=1
    for build in ${_strip_builds[@]}; do
      if [ "$_to_uninstall" = "$i" ]; then
        rm -rf "proton_tkg_$build" && _available_builds=( `ls -d proton_tkg_* | sort -V` ) && _newest_build="${_available_builds[-1]//proton_tkg_/}" && sed -i "s/\"Proton-tkg $build\"/\"Proton-tkg ${_newest_build[@]}\"/" $_config_file
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
    if [ "$_uninstall_more" = "y" ]; then
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

if [ "$1" = "clean" ]; then
  proton_tkg_uninstaller
elif [ "$1" = "build_vrclient" ]; then
  build_vrclient
elif [ "$1" = "build_lsteamclient" ]; then
  build_lsteamclient
elif [ "$1" = "build_vkd3d" ]; then
  build_vkd3d
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

  # Build vkd3d
  if [ "$_build_vkd3d" = "true" ]; then
    build_vkd3d
  fi

  cd "$_nowhere"

  # We'll need a token to register to wine-tkg-git - keep one for us to steal wine-tkg-git options later
  echo -e "_proton_tkg_path='${_nowhere}'\n_no_steampath='${_no_steampath}'" > proton_tkg_token && cp proton_tkg_token "${_wine_tkg_git_path}/"

  # Now let's build
  cd "$_wine_tkg_git_path"
  if [ ! -e "/usr/bin/makepkg" ] || [ "$_nomakepkg" = "true" ]; then
    rm -f "$_wine_tkg_git_path"/non-makepkg-builds/HL3_confirmed
    ./non-makepkg-build.sh
  else
    makepkg -s || true
  fi

  # Wine-tkg-git has injected versioning and settings in the token for us, so get the values back
  source "$_nowhere/proton_tkg_token"

  # Copy the resulting package in here to begin our work
  if [ -e "$_proton_pkgdest"/../HL3_confirmed ]; then

    cd $_nowhere

    # Create required dirs and clean
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
      # Clone Proton tree as we need to build some tools from it
      git clone https://github.com/ValveSoftware/Proton || true # It'll complain the path already exists on subsequent builds
      cd Proton
      git reset --hard HEAD
      git clean -xdf
      git pull
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

    # Grab share template and inject version
    echo "1552061114 proton-tkg-$_protontkg_version" > "$_nowhere/proton_dist_tmp/version" && cp -r "$_nowhere/proton_template/share"/* "$_nowhere/proton_dist_tmp/share"/

    # Create the dxvk dirs
    mkdir -p "$_nowhere/proton_dist_tmp/lib64/wine/dxvk"
    mkdir -p "$_nowhere/proton_dist_tmp/lib/wine/dxvk"

    # Build vrclient libs
    if [ "$_steamvr_support" = "true" ]; then
      build_vrclient
      cd Proton
    fi

    # Build lsteamclient libs
    build_lsteamclient

    # Build steam helper
    build_steamhelper

    # Inject vkd3d libs in our wine-tkg-git build
    if [ "$_build_vkd3d" = "true" ]; then
      for f in "$_nowhere"/vkd3d-fork-build/build/lib64-vkd3d/out/lib/libvkd3d*so*; do
        strip "$f" && cp -v "$f" proton_dist_tmp/lib64/
      done
      for f in "$_nowhere"/vkd3d-fork-build/build/lib32-vkd3d/out/lib/libvkd3d*so*; do
        strip "$f" && cp -v "$f" proton_dist_tmp/lib/
      done
    fi

    # dxvk
    if [ "$_use_dxvk" != "false" ]; then
      if [ ! -d "$_nowhere"/dxvk ] || [ "$_use_dxvk" = "release" ]; then
        rm -rf "$_nowhere"/dxvk
        download_dxvk_version
        tar -xvf dxvk-*.tar.gz >/dev/null 2>&1
        rm -f dxvk-*.tar.*
        mv "$_nowhere"/dxvk-* "$_nowhere"/dxvk
      fi
      # Remove d3d10.dll and d3d10_1.dll when using a 5.3 base or newer - https://github.com/doitsujin/dxvk/releases/tag/v1.6
      if [ "$_dxvk_minimald3d10" = "true" ]; then
        cp -v dxvk/x64/{d3d10core.dll,d3d11.dll,d3d9.dll,dxgi.dll} proton_dist_tmp/lib64/wine/dxvk/
        cp -v dxvk/x32/{d3d10core.dll,d3d11.dll,d3d9.dll,dxgi.dll} proton_dist_tmp/lib/wine/dxvk/
      else
        cp -v dxvk/x64/{d3d10.dll,d3d10_1.dll,d3d10core.dll,d3d11.dll,d3d9.dll,dxgi.dll} proton_dist_tmp/lib64/wine/dxvk/
        cp -v dxvk/x32/{d3d10.dll,d3d10_1.dll,d3d10core.dll,d3d11.dll,d3d9.dll,dxgi.dll} proton_dist_tmp/lib/wine/dxvk/
      fi
      if [ -e dxvk/x64/dxvk_config.dll ]; then
        cp -v dxvk/x64/dxvk_config.dll proton_dist_tmp/lib64/wine/dxvk/
      fi
      if [ -e dxvk/x32/dxvk_config.dll ]; then
        cp -v dxvk/x32/dxvk_config.dll proton_dist_tmp/lib/wine/dxvk/
      fi
    fi

    echo ''
    echo "Packaging..."

    # Package
    cd proton_dist_tmp && tar -zcf proton_dist.tar.gz bin/ include/ lib64/ lib/ share/ version && mv proton_dist.tar.gz ../"proton_tkg_$_protontkg_version"
    cd "$_nowhere" && rm -rf proton_dist_tmp

    # Grab conf template and inject version
    echo "1552061114 proton-tkg-$_protontkg_version" > "proton_tkg_$_protontkg_version/version" && cp "proton_template/conf"/* "proton_tkg_$_protontkg_version"/ && sed -i -e "s|TKGVERSION|$_protontkg_version|" "proton_tkg_$_protontkg_version/compatibilitytool.vdf"

    # Patch our proton script to use the current proton tree prefix version value
    _prefix_version=$(cat "$_nowhere/Proton/proton" | grep "CURRENT_PREFIX_VERSION=")
    sed -i -e "s|CURRENT_PREFIX_VERSION=\"TKG\"|${_prefix_version}|" "proton_tkg_$_protontkg_version/proton"

    # Patch our proton script to make use of the steam helper on 4.0+
    if [[ $_proton_branch != proton_3.* ]] && [ "$_proton_use_steamhelper" = "true" ]; then
      cd "$_nowhere/proton_tkg_$_protontkg_version"
      patch -Np1 < "$_nowhere/proton_template/steam.exe.patch" && rm -f proton.orig
      cd "$_nowhere"
    fi

    # Patch our proton script to allow for VR support
    if [ "$_steamvr_support" = "true" ]; then
      cd "$_nowhere/proton_tkg_$_protontkg_version"
      patch -Np1 < "$_nowhere/proton_template/vr-support.patch" && rm -f proton.orig
      cd "$_nowhere"
    fi

    # Patch our proton script to handle minimal d3d10 implementation for dxvk on Wine 5.3+
    if [ "$_dxvk_minimald3d10" = "true" ]; then
      cd "$_nowhere/proton_tkg_$_protontkg_version"
      patch -Np1 < "$_nowhere/proton_template/dxvk_minimald3d10.patch" && rm -f proton.orig
      cd "$_nowhere"
      # Patch our proton script to handle dxvk_config lib
      if [ -e "$_nowhere"/dxvk/x64/dxvk_config.dll ]; then
        cd "$_nowhere/proton_tkg_$_protontkg_version"
        patch -Np1 < "$_nowhere/proton_template/dxvk_config_support.patch" && rm -f proton.orig
        cd "$_nowhere"
      fi
    fi

    # Patch our makepkg version of the proton script to not create default prefix and use /tmp/dist.lock
    if [ "$_ispkgbuild" = "true" ]; then
      cd "$_nowhere/proton_tkg_$_protontkg_version"
      patch -Np1 < "$_nowhere/proton_template/makepkg_adjustments.patch" && rm -f proton.orig
      cd "$_nowhere"
    fi

    # Patch our proton script to remove mfplay dll override when _proton_mf_hacks is disabled
    if [ "$_proton_mf_hacks" != "true" ]; then
      sed -i '/.*#disable built-in mfplay.*/d' "proton_tkg_$_protontkg_version/proton"
    fi

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

    cd $_nowhere

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
            echo ""
            read -rp "Do you want to run the uninstaller to remove previous/superfluous builds? N/y: " _ask_uninstall;
            if [ "$_ask_uninstall" = "y" ]; then
              proton_tkg_uninstaller
            fi
          fi
        fi
      else
        echo "####################################################################################################"
        echo ""
        echo " Your Proton-tkg build is now available in $_nowhere/proton_tkg_$_protontkg_version"
        echo ""
        echo "####################################################################################################"
      fi
    fi
  else
    rm $_nowhere/proton_tkg_token
    echo "The required initial proton_dist build is missing! Wine-tkg-git compilation may have failed."
  fi
fi
