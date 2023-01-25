#!/bin/bash

_exit_cleanup() {
  if [ "$pkgver" != "0" ]; then
    sed -i "s/pkgver=$pkgver.*/pkgver=0/g" "$_where"/PKGBUILD
  fi

  # Proton-tkg specifics to send to token
  if [ -e "$_where"/BIG_UGLY_FROGMINER ] && [ "$_EXTERNAL_INSTALL" = "proton" ] && [ -n "$_proton_tkg_path" ] && [ -d "${srcdir}"/"${_winesrcdir}" ]; then
    if [ -n "$_PROTON_NAME_ADDON" ]; then
      if [ "$_ispkgbuild" = "true" ]; then
        echo "_protontkg_version='makepkg.${_PROTON_NAME_ADDON}'" >> "$_proton_tkg_path"/proton_tkg_token
        echo "_protontkg_true_version='${pkgver}.${_PROTON_NAME_ADDON}'" >> "$_proton_tkg_path"/proton_tkg_token
      else
        echo "_protontkg_version='${pkgver}.${_PROTON_NAME_ADDON}'" >> "$_proton_tkg_path"/proton_tkg_token
      fi
    else
      if [ "$_ispkgbuild" = "true" ]; then
        echo "_protontkg_version=makepkg" >> "$_proton_tkg_path"/proton_tkg_token
        echo "_protontkg_true_version='${pkgver}'" >> "$_proton_tkg_path"/proton_tkg_token
      else
        echo "_protontkg_version='${pkgver}'" >> "$_proton_tkg_path"/proton_tkg_token
      fi
    fi
    if [[ $pkgver = 3.* ]]; then
      echo '_proton_branch="proton_3.16"' >> "$_proton_tkg_path"/proton_tkg_token
    elif [[ $pkgver = 4.* ]]; then
      echo '_proton_branch="proton_4.11"' >> "$_proton_tkg_path"/proton_tkg_token
    else
      echo "_proton_branch=${_proton_branch}" >> "$_proton_tkg_path"/proton_tkg_token
    fi
    if [[ $pkgver = *bleeding.edge* ]]; then
      echo "_bleeding_tag='${_bleeding_tag//-wine/}'" >> "$_proton_tkg_path"/proton_tkg_token
    fi
    if [ -n "$_proton_dxvk_configfile" ]; then
      echo "_proton_dxvk_configfile=${_proton_dxvk_configfile}" >> "$_proton_tkg_path"/proton_tkg_token
    fi
    if [ -n "$_proton_dxvk_hud" ]; then
      echo "_proton_dxvk_hud=${_proton_dxvk_hud}" >> "$_proton_tkg_path"/proton_tkg_token
    fi
    echo "_skip_uninstaller=${_skip_uninstaller}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_no_autoinstall=${_no_autoinstall}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_pkg_strip=${_pkg_strip}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_nvapi_disable=${_proton_nvapi_disable}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_winedbg_disable=${_proton_winedbg_disable}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_conhost_disable=${_proton_conhost_disable}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_pulse_lowlat=${_proton_pulse_lowlat}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_force_LAA=${_proton_force_LAA}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_shadercache_path=${_proton_shadercache_path}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_winetricks=${_proton_winetricks}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_dxvk_async=${_proton_dxvk_async}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_use_steamhelper=${_proton_use_steamhelper}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_mf_hacks=${_proton_mf_hacks}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_dxvk_dxgi=${_dxvk_dxgi}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_use_dxvk=${_use_dxvk}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_dxvk_version=${_dxvk_version}" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_use_vkd3dlib='${_use_vkd3dlib}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_pkgdest='${pkgdir}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_proton_branch_exp='${_proton_branch_exp}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_steamvr_support='${_steamvr_support}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_NUKR='${_NUKR}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_winesrcdir='${_winesrcdir}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_standard_dlopen='${_standard_dlopen}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_processinfoclass='${_processinfoclass}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_no_loader_array='${_no_loader_array}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "CUSTOM_MINGW_PATH='${CUSTOM_MINGW_PATH}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "CUSTOM_GCC_PATH='${CUSTOM_GCC_PATH}'" >> "$_proton_tkg_path"/proton_tkg_token
    if ( cd "${srcdir}"/"${_winesrcdir}" && git merge-base --is-ancestor 1e478b804f72a9b5122fc6adafac5479b816885e HEAD ) && [ "$_dxvk_minimald3d10" != "false" ]; then
      echo "_dxvk_minimald3d10='true'" >> "$_proton_tkg_path"/proton_tkg_token
    fi
    echo "_build_mediaconv='${_build_mediaconv}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_build_gstreamer='${_build_gstreamer}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_lib32_gstreamer='${_lib32_gstreamer}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_build_ffmpeg='${_build_ffmpeg}'" >> "$_proton_tkg_path"/proton_tkg_token
    if [[ "$_LOCAL_PRESET" = valve* ]]; then
      echo "_build_faudio='${_build_faudio}'" >> "$_proton_tkg_path"/proton_tkg_token # FAudio is builtin on current usptream wine
    fi
    echo "_reuse_built_gst='${_reuse_built_gst}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_unfrog='${_unfrog}'" >> "$_proton_tkg_path"/proton_tkg_token
    echo "_NOLIB32='${_NOLIB32}'" >> "$_proton_tkg_path"/proton_tkg_token
  fi

  rm -f "$_where"/BIG_UGLY_FROGMINER && msg2 'Removed BIG_UGLY_FROGMINER - Ribbit' # state tracker end

  if [ "$_NUKR" = "true" ]; then
    # Sanitization
    rm -rf "$srcdir"/"$_esyncsrcdir"
    rm -rf "$srcdir"/*.patch
    rm -rf "$srcdir"/*.tgz
    rm -rf "$srcdir"/*.conf
    rm -f "$srcdir"/wine-tkg
    rm -f "$srcdir"/wine-tkg-interactive
    rm -f "$_where"/proton_tkg_token && msg2 'Removed Proton-tkg token - Valve Ribbit' # state tracker end
    msg2 'exit cleanup done'
  fi

  # Remove temporarily copied patches & other potential fluff
  rm -f "$_where"/wine-tkg
  rm -f "$_where"/wine-tkg-interactive
  rm -f "$_where"/wine-tkg.install
  rm -rf "$_where"/*.patch
  rm -rf "$_where"/*.my*
  rm -rf "$_where"/*.conf
  rm -rf "$_where"/*.orig
  rm -rf "$_where"/*.rej
  rm -rf "$_where"/temp

  if [ -n "$_buildtime64" ]; then
    msg2 "Compilation time for 64-bit wine: \n$_buildtime64\n"
  fi
  if [ -n "$_buildtime32" ]; then
    msg2 "Compilation time for 32-bit wine: \n$_buildtime32\n"
  fi
}

_cfgstring() {
  if [[ "$_cfgstringin" = /home/* ]]; then
    _cfgstringout="~/$( echo $_cfgstringin | cut -d'/' -f4-)"
  else
    _cfgstringout="$_cfgstringin"
  fi
}

update_configure() {
  _file="./configure"

  if ! cp -a "$_file" "$_file.old"; then
    abort "failed to create $_file.old"
  fi

  if ! autoreconf -f; then
    rm "$_file.old"
    unset _file
    return 1
  fi

  # This is undefined behaviour when off_t is 32-bit, see https://launchpad.net/ubuntu/+source/autoconf/2.69-6
  # GE has reported RDR2 online issues with the fix applied (which staging applies), so let's restore the broken ways
  sed -i'' -e "s|^#define LARGE_OFF_T ((((off_t) 1 << 31) << 31) - 1 + (((off_t) 1 << 31) << 31))\$|#define LARGE_OFF_T (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))|g" "$_file"
  sed -i'' -e "s|^#define LARGE_OFF_T (((off_t) 1 << 31 << 31) - 1 + ((off_t) 1 << 31 << 31))\$|#define LARGE_OFF_T (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))|g" "$_file"
  unset _large_off_old _large_off_new

  # Restore original timestamp when nothing changed
  if ! cmp "$_file.old" "$_file" >/dev/null; then
    rm "$_file.old"
  else
    mv "$_file.old" "$_file"
  fi

  unset _file
  return 0
}

_init() {
msg2 '       .---.`               `.---.'
msg2 '    `/syhhhyso-           -osyhhhys/`'
msg2 '   .syNMdhNNhss/``.---.``/sshNNhdMNys.'
msg2 '   +sdMh.`+MNsssssssssssssssNM+`.hMds+'
msg2 '   :syNNdhNNhssssssssssssssshNNhdNNys:'
msg2 '    /ssyhhhysssssssssssssssssyhhhyss/'
msg2 '    .ossssssssssssssssssssssssssssso.'
msg2 '   :sssssssssssssssssssssssssssssssss:'
msg2 '  /sssssssssssssssssssssssssssssssssss/'
msg2 ' :sssssssssssssoosssssssoosssssssssssss:'
msg2 ' osssssssssssssoosssssssoossssssssssssso'
msg2 ' osssssssssssyyyyhhhhhhhyyyyssssssssssso'
msg2 ' /yyyyyyhhdmmmmNNNNNNNNNNNmmmmdhhyyyyyy/'
msg2 '  smmmNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmms'
msg2 '   /dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd/'
msg2 '    `:sdNNNNNNNNNNNNNNNNNNNNNNNNNds:`'
msg2 '       `-+shdNNNNNNNNNNNNNNNdhs+-`'
msg2 '             `.-:///////:-.`'
msg2 ''

  # load default configuration from files
  if [ -e "$_where"/proton_tkg_token ]; then
    source "$_where"/proton_tkg_token
    source "$_proton_tkg_path"/proton-tkg.cfg
    source "$_proton_tkg_path"/proton-tkg-profiles/advanced-customization.cfg
  else
    source "$_where"/customization.cfg
    source "$_where"/wine-tkg-profiles/advanced-customization.cfg
    _EXTERNAL_INSTALL_TYPE="opt"
  fi

  # Load external configuration file if present. Available variable values will overwrite customization.cfg ones.
  if [ -e "$_where/wine-tkg-userpatches/user.cfg" ]; then
    source "$_where/wine-tkg-userpatches/user.cfg" && msg2 "User.cfg config loaded"
  elif [ -e "$_EXT_CONFIG_PATH" ]; then
    source "$_EXT_CONFIG_PATH" && msg2 "External configuration file $_EXT_CONFIG_PATH will be used to override customization.cfg values." && msg2 ""
  fi

  if [ "$_NOINITIALPROMPT" = "true" ] || [ -n "$_LOCAL_PRESET" ] || [ -n "$_DEPSHELPER" ]; then
    msg2 'Initial prompt skipped. Do you remember what it said? 8)'
  else
    # If the state tracker isn't found, prompt the user with useful stuff.
    # This is to prevent the prompt to come back until packaging is done
    if [ ! -e "$_where"/BIG_UGLY_FROGMINER ]; then
      msg2 '#################################################################'
      msg2 ''
      msg2 'You can configure your wine build flavour (right now for example)'
      if [ -e "$_EXT_CONFIG_PATH" ]; then
        msg2 "by editing the $_EXT_CONFIG_PATH file."
        msg2 ''
        msg2 'In case you are only using a partial config file, remaining'
        msg2 'values will be loaded from the .cfg file next to this script !'
      elif [ -e "$_proton_tkg_path"/proton_tkg_token ]; then
        msg2 'by editing the proton-tkg.cfg file in the proton-tkg dir,'
        msg2 'or by creating a custom config, for example'
        msg2 '~/.config/frogminer/proton-tkg.cfg (path set in config file)'
        msg2 'to override some or all of its values.'
      else
        msg2 'by editing the customization.cfg file next to this PKGBUILD,'
        msg2 'or by creating a custom config, for example'
        msg2 '~/.config/frogminer/wine-tkg.cfg (path set in config file)'
        msg2 'to override some or all of its values.'
      fi
      msg2 ''
      msg2 "Current path is '$_where'"
      msg2 ''
      msg2 'If you are rebuilding using the same configuration, you may want'
      msg2 'to delete/move previously built package if in the same dir.'
      msg2 ''
      msg2 '###################################TkG##########was##########here'
      read -rp "When you are ready, press enter to continue."

      if [ -e "$_where/wine-tkg-userpatches/user.cfg" ]; then
        source "$_where/wine-tkg-userpatches/user.cfg" && msg2 "User.cfg config loaded"
      elif [ -e "$_EXT_CONFIG_PATH" ]; then
        source "$_EXT_CONFIG_PATH" && msg2 "External config loaded" # load external configuration from file again, in case of changes.
      else
        # load default configuration from file again, in case of change
        if [ -e "$_proton_tkg_path"/proton_tkg_token ]; then
          source "$_proton_tkg_path"/proton-tkg.cfg
          source "$_proton_tkg_path"/proton-tkg-profiles/advanced-customization.cfg
        else
          source "$_where"/customization.cfg
          source "$_where"/wine-tkg-profiles/advanced-customization.cfg
        fi
      fi
    fi
  fi

  # makepkg: grab temp profile data in flight - Else the makepkg loop clears and forgets
  if [ -e "$_where"/temp ]; then
    source "$_where"/temp
  fi

  # Check for proton-tkg token to prevent broken state as we need to enforce some defaults
  if [ -e "$_proton_tkg_path"/proton_tkg_token ] && [ -n "$_proton_tkg_path" ]; then
    if [[ "$_LOCAL_PRESET" != valve* ]] && [ "$_LOCAL_PRESET" != "none" ]; then
      _LOCAL_PRESET=""
    fi
    # makepkg proton pkgver loop hack
    if [ "$_ispkgbuild" = "true" ] && [ -e "$_proton_tkg_path"/proton_tkg_tmp ]; then
      source "$_proton_tkg_path"/proton_tkg_tmp
    fi
    if [ -z "$_LOCAL_PRESET" ]; then
      msg2 "No _LOCAL_PRESET set in .cfg. Please select your desired base:"
      warning "With Valve trees, most wine-specific customization options will be ignored such as game-specific patches, esync/fsync/fastsync or Proton-specific features support. Those patches and features are for the most part already in, but some bits deemed useful such as FSR support for Proton's fshack are made available through community patches. Staging and GE patches are available through regular .cfg options."
      read -p "    What kind of Proton base do you want?`echo $'\n    > 1.Valve Proton Experimental Bleeding Edge (Recommended for gaming on the edge)\n      2.Valve Proton Experimental\n      3.Valve Proton\n      4.Wine upstream Proton (The most experimental)\n    choice[1-4?]: '`" CONDITION;
      if [ "$CONDITION" = "2" ]; then
        _LOCAL_PRESET="valve-exp"
      elif [ "$CONDITION" = "3" ]; then
        _LOCAL_PRESET="valve"
      elif [ "$CONDITION" = "4" ]; then
        _LOCAL_PRESET=""
      else
        _LOCAL_PRESET="valve-exp-bleeding"
      fi
      echo "_LOCAL_PRESET='$_LOCAL_PRESET'" > "$_where"/temp
      # makepkg proton pkgver loop hack
      if [ "$_ispkgbuild" = "true" ]; then
        if [ -z "$_LOCAL_PRESET" ]; then
          _LOCAL_PRESET="none"
        fi
        echo "_LOCAL_PRESET='$_LOCAL_PRESET'" >> "$_proton_tkg_path"/proton_tkg_tmp
      fi
    fi
    _EXTERNAL_INSTALL="proton"
    _EXTERNAL_NOVER="false"
    _nomakepkg_nover="true"
    if [[ "$_LOCAL_PRESET" = valve* ]]; then
      _NOLIB32="false"
      _NOLIB64="false"
    fi
    _esync_version=""
    _use_faudio="true"
    _highcorecount_fix="true"
    _use_mono="true"
    if [ "$_use_dxvk" = "true" ] || [ "$_use_dxvk" = "release" ]; then
      _use_dxvk="release"
      _dxvk_dxgi="true"
    fi
    #if [ "$_ispkgbuild" = "true" ]; then
    #  _steamvr_support="false"
    #fi
    if [ "$_use_latest_mono" = "true" ]; then
      if ! [ -f "$_where"/$( curl -s https://api.github.com/repos/madewokherd/wine-mono/releases/latest | grep "browser_download_url.*x86.msi" | cut -d : -f 2,3 | tr -d \" | sed -e "s|.*/||") ]; then
        rm -f "$_where"/wine-mono* # Remove any existing older mono
        msg2 "Downloading latest mono..."
        ( curl -s https://api.github.com/repos/madewokherd/wine-mono/releases/latest | grep "browser_download_url.*x86.msi" | cut -d : -f 2,3 | tr -d \" | wget -qi - )
      fi
    fi
  elif [ "$_EXTERNAL_INSTALL" = "proton" ]; then
    error "It looks like you're attempting to build a Proton version of wine-tkg-git."
    error "This special option doesn't use pacman and requires you to run 'proton-tkg.sh' script from proton-tkg dir."
    _exit_cleanup
    exit
  else
    if [ ! -e "$_where"/BIG_UGLY_FROGMINER ] && [ -z "$_LOCAL_PRESET" ]; then
      msg2 "No _LOCAL_PRESET set in .cfg. Please select your desired base (or hit enter for default) :"
      warning "! \"mainline\" and \"staging\" options will make clean & untouched wine and wine-staging builds, ignoring your .cfg settings !"
      warning "! \"valve\" profiles will use Valve proton wine trees instead of upstream, ignoring many incompatibble .cfg settings !"
      warning "! \"default-tkg\" profile will use the main customization.cfg and wine-tkg-profiles/advanced-customization.cfg files !"

      i=0
      for _profiles in "$_where/wine-tkg-profiles"/wine-tkg-*.cfg; do
        _GOTCHA=( "${_profiles//*\/wine-tkg-/}" )
        msg2 "  $i - ${_GOTCHA//.cfg/}" && ((i+=1))
      done
      msg2 "  $i - other & legacy"

      _separator="$i"
      ((i+=1))

      read -rp "  choice [0-$(($i-1))]: " _SELECT_PRESET;

      if [ "$_SELECT_PRESET" = "$_separator" ]; then
        i=0
        for _profiles in "$_where/wine-tkg-profiles"/legacy/wine-tkg-*.cfg; do
          _GOTCHA=( "${_profiles//*\/wine-tkg-/}" )
          msg2 "  $i - ${_GOTCHA//.cfg/}" && ((i+=1))
        done
        read -rp "  choice [0-$(($i-1))]: " _SELECT_PRESET;
        _profiles=( `ls "$_where/wine-tkg-profiles"/legacy/wine-tkg-*.cfg` )
      else
        _profiles=( `ls "$_where/wine-tkg-profiles"/wine-tkg-*.cfg` )
      fi
      _strip_profiles=( "${_profiles[@]//*\/wine-tkg-/}" )

      _LOCAL_PRESET="${_strip_profiles[$_SELECT_PRESET]//.cfg/}"

      # Clear the default preset
      if [ "$_LOCAL_PRESET" = "default-tkg" ]; then
        _LOCAL_PRESET="none"
      fi

      echo "_LOCAL_PRESET='$_LOCAL_PRESET'" > "$_where"/temp
    fi
  fi

  # Load preset configuration files if present and selected. All values will overwrite customization.cfg ones.
  if [ -n "$_LOCAL_PRESET" ] && ( [ -e "$_where"/wine-tkg-profiles/wine-tkg-"$_LOCAL_PRESET".cfg ] || [ -e "$_where"/wine-tkg-profiles/legacy/wine-tkg-"$_LOCAL_PRESET".cfg ] ); then
    if [ "$_LOCAL_PRESET" = "valve" ] || [[ "$_LOCAL_PRESET" = valve-exp* ]]; then
      if [ -e "$_where"/wine-tkg-profiles/wine-tkg-"$_LOCAL_PRESET".cfg ]; then
        source "$_where"/wine-tkg-profiles/wine-tkg-"$_LOCAL_PRESET".cfg
      elif [ -e "$_where"/wine-tkg-profiles/legacy/wine-tkg-"$_LOCAL_PRESET".cfg ]; then
        source "$_where"/wine-tkg-profiles/legacy/wine-tkg-"$_LOCAL_PRESET".cfg
      fi
      msg2 "Preset configuration $_LOCAL_PRESET will be used to override customization.cfg values." && msg2 ""
    else
      source "$_where"/wine-tkg-profiles/wine-tkg.cfg
      if [ -e "$_where"/wine-tkg-profiles/wine-tkg-"$_LOCAL_PRESET".cfg ]; then
        source "$_where"/wine-tkg-profiles/wine-tkg-"$_LOCAL_PRESET".cfg
      elif [ -e "$_where"/wine-tkg-profiles/legacy/wine-tkg-"$_LOCAL_PRESET".cfg ]; then
        source "$_where"/wine-tkg-profiles/legacy/wine-tkg-"$_LOCAL_PRESET".cfg
      fi
      msg2 "Preset configuration $_LOCAL_PRESET will be used to override customization.cfg values." && msg2 ""
    fi
  elif [ -n "$_LOCAL_PRESET" ] && [ "$_LOCAL_PRESET" != "none" ]; then
    error "Preset '$_LOCAL_PRESET' was not found anywhere! exiting..." && exit 1
  fi

  # Disable undesirable patchsets when using official proton wine source
  if [[ "$_custom_wine_source" = *"ValveSoftware"* ]]; then
    _clock_monotonic="false"
    _FS_bypass_compositor="false"
    _use_esync="false"
    _use_fsync="false"
    _use_fastsync="false"
    _fsync_futex_waitv="false"
#    _use_staging="false"
    _proton_fs_hack="false"
    _proton_rawinput="false"
    _large_address_aware="false"
    _proton_mf_hacks="false"
    _update_winevulkan="false"
    _steam_fix="false"
    _mtga_fix="false"
    _protonify="false"
    _childwindow_fix="false"
    _shared_gpu_resources="false"
    _plasma_systray_fix="false"
    _wined3d_additions="false"
    _re4_fix="false"
    _assettocorsa_hudperf_fix="false"
    _msvcrt_nativebuiltin="false"
    _use_josh_flat_theme="false"
    _tabtip="false"
    _sdl_joy_support="false"
    _unfrog="true"
  fi
}

_pkgnaming() {
  if [ -n "$_PKGNAME_OVERRIDE" ]; then
    if [ "$_PKGNAME_OVERRIDE" = "none" ]; then
      pkgname="${pkgname}"
    else
      pkgname="${pkgname}-${_PKGNAME_OVERRIDE}"
    fi

    # Add trailing -git for non-valve presets
    if [ -n "$_LOCAL_PRESET" ] && [[ "$_custom_wine_source" != *"ValveSoftware"* ]]; then
      pkgname+="-git"
    fi
    msg2 "Overriding default pkgname. New pkgname: ${pkgname}"
  else
    if [ "$_use_staging" = "true" ]; then
      pkgname+="-staging"
      msg2 "Using staging patchset"
    fi

    if [ "$_use_esync" = "true" ]; then
      if [ "$_use_fsync" = "true" ]; then
        pkgname+="-fsync"
        msg2 "Using fsync patchset"
      else
        pkgname+="-esync"
        msg2 "Using esync patchset"
      fi
    fi
    if [ "$_use_legacy_gallium_nine" = "true" ]; then
      pkgname+="-nine"
      msg2 "Using gallium nine patchset (legacy)"
    fi
    # Add trailing -git for non-overriden pkgnames
    pkgname+="-git"
  fi

  # External install
  if [ "$_EXTERNAL_INSTALL" = "true" ]; then
    pkgname+="-$_EXTERNAL_INSTALL_TYPE"
    msg2 "Installing to $_DEFAULT_EXTERNAL_PATH/$pkgname"
  elif [ "$_EXTERNAL_INSTALL" = "proton" ]; then
    pkgname="proton_dist"
    _DEFAULT_EXTERNAL_PATH="$HOME/.steam/root/compatibilitytools.d"
    if [ "$_ispkgbuild" != "true" ]; then
      msg2 "Installing to $_DEFAULT_EXTERNAL_PATH/proton_tkg"
    fi
  fi
}

user_patcher() {
	# To patch the user because all your base are belong to us
	local _patches=("$_where"/*."${_userpatch_ext}revert")
	if [ ${#_patches[@]} -ge 2 ] || [ -e "${_patches}" ]; then
	  if [ "$_user_patches_no_confirm" != "true" ]; then
	    msg2 "Found ${#_patches[@]} 'to revert' userpatches for ${_userpatch_target}:"
	    printf '%s\n' "${_patches[@]}"
	    read -rp "Do you want to install it/them? - Be careful with that ;)"$'\n> N/y : ' _CONDITION;
	  fi
	  if [[ "$_CONDITION" =~ [yY] ]] || [ "$_user_patches_no_confirm" = "true" ]; then
	    for _f in ${_patches[@]}; do
	      if [ -e "${_f}" ]; then
	        msg2 "######################################################"
	        msg2 ""
	        msg2 "Reverting your own ${_userpatch_target} patch ${_f}"
	        msg2 ""
	        msg2 "######################################################"
	        echo -e "\nReverting your own patch ${_f##*/}" >> "$_where"/prepare.log #" Coloring confusion
	        if ! patch -Np1 -R < "${_f}" >> "$_where"/prepare.log; then
	          error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience."
	          if [ -n "$_last_known_good_mainline" ] || [ -n "$_last_known_good_staging" ]; then
	            msg2 "To use the last known good mainline version, please set _plain_version=\"$_last_known_good_mainline\" in your .cfg"
	            msg2 "To use the last known good staging version, please set _staging_version=\"$_last_known_good_staging\" in your .cfg (requires _use_staging=\"true\")"
	          fi
	          exit 1
	        fi
	        echo -e "Reverted your own patch ${_f##*/}" >> "$_where"/last_build_config.log #" Coloring confusion
	      fi
	    done
	  fi
	fi

	_patches=("$_where"/*."${_userpatch_ext}patch")
	if [ ${#_patches[@]} -ge 2 ] || [ -e "${_patches}" ]; then
	  if [ "$_user_patches_no_confirm" != "true" ]; then
	    msg2 "Found ${#_patches[@]} userpatches for ${_userpatch_target}:"
	    printf '%s\n' "${_patches[@]}"
	    read -rp "Do you want to install it/them? - Be careful with that ;)"$'\n> N/y : ' _CONDITION;
	  fi
	  if [[ "$_CONDITION" =~ [yY] ]] || [ "$_user_patches_no_confirm" = "true" ]; then
	    for _f in ${_patches[@]}; do
	      if [ -e "${_f}" ]; then
	        msg2 "######################################################"
	        msg2 ""
	        msg2 "Applying your own ${_userpatch_target} patch ${_f}"
	        msg2 ""
	        msg2 "######################################################"
	        echo -e "\nApplying your own patch ${_f##*/}" >> "$_where"/prepare.log #" Coloring confusion
	        if ! patch -Np1 < "${_f}" >> "$_where"/prepare.log; then
	          error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience."
	          if [ -n "$_last_known_good_mainline" ] || [ -n "$_last_known_good_staging" ]; then
	            msg2 "To use the last known good mainline version, please set _plain_version=\"$_last_known_good_mainline\" in your .cfg"
	            msg2 "To use the last known good staging version, please set _staging_version=\"$_last_known_good_staging\" in your .cfg (requires _use_staging=\"true\")"
	          fi
	          exit 1
	        fi
	        echo -e "Applied your own patch ${_f##*/}" >> "$_where"/last_build_config.log #" Coloring confusion
	      fi
	    done
	  fi
	fi
}

_describe_wine() {
  if [ -e "$_where"/temp ]; then
    source "$_where"/temp
  fi
  if [ "$_LOCAL_PRESET" = "valve-exp-bleeding" ]; then
    # On experimental bleeding edge, we want to keep only the first 7 out of 13 bits
    if [ "$_ismakepkg" = "true" ]; then
      echo "$_bleeding_tag" | sed 's/\([^-]*-g\)/r\1/;s/-/./g;s/^v//;s/\.rc/rc/;s/^wine\.//;s/\.wine//' | cut -d'.' -f1-7 | sed 's/experimental.//;s/bleeding.edge.//'
    else
      echo "$_bleeding_tag" | sed 's/\([^-]*-g\)/r\1/;s/-/./g;s/^v//;s/\.rc/rc/;s/^wine\.//;s/\.wine//' | cut -d'.' -f1-7
    fi
  else
    if [ "$_ismakepkg" = "true" ]; then
      git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g;s/^v//;s/\.rc/rc/;s/^wine\.//;s/experimental.//'
    else
      git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g;s/^v//;s/\.rc/rc/;s/^wine\.//'
    fi
  fi
}

_describe_other() {
  git describe --long --tags --always | sed 's/\([^-]*-g\)/r\1/;s/-/./g;s/^v//'
}

_committer() {
  if [ "$_generate_patchsets" != "false" ]; then
    ( git add . && git commit -m "$_commitmsg" && git format-patch -n HEAD^ || true ) >/dev/null 2>&1
  fi
}

_source_cleanup() {
	if [ "$_NUKR" != "debug" ]; then
	  if [ "$_use_staging" = "true" ]; then
	    cd "${srcdir}"/"${_stgsrcdir}"

	    # restore the targetted trees to their git origin state
	    # for the patches not to fail on subsequent aborted builds
	    msg2 'Cleaning wine-staging source code tree...'
	    git reset --hard HEAD 	# restore tracked files
	    git clean -xdf 			# delete untracked files
	  fi

	  cd "${srcdir}"/"${_winesrcdir}"

	  msg2 'Cleaning wine source code tree...'
	  git reset --hard HEAD 	# restore tracked files
	  git clean -xdf 			# delete untracked files
	fi
}

_prepare() {
  # holds extra arguments to staging's patcher script, if applicable
  local _staging_args=()

  source "$_where"/wine-tkg-patches/hotfixes/earlyhotfixer

  # grabs userdefined staging args if any
  _staging_args+=($_staging_userargs)

  if [ "$_use_staging" = "true" ] && [ "$_staging_upstreamignore" != "true" ] && [[ "$_custom_wine_source" != *"ValveSoftware"* ]]; then
    cd "${srcdir}"/"${_winesrcdir}"
    # change back to the wine upstream commit that this version of wine-staging is based in
    msg2 'Changing wine HEAD to the wine-staging base commit...'
    if [ ! -e ../"$_stgsrcdir"/staging/upstream-commit ] || $( git merge-base "$( cat ../"$_stgsrcdir"/staging/upstream-commit )" --is-ancestor "$(../"$_stgsrcdir"/patches/patchinstall.sh --upstream-commit)" ); then
      msg2 "Using patchinstall.sh --upstream-commit"
      # Use patchinstall.sh --upstream-commit
      git -c advice.detachedHead=false checkout "$(../"$_stgsrcdir"/patches/patchinstall.sh --upstream-commit)"
    else
      msg2 "Using upstream-commit file"
      # Use upstream-commit file if patchinstall.sh --upstream-commit doesn't report the same upstream commit target
      git -c advice.detachedHead=false checkout "$( cat ../"$_stgsrcdir"/staging/upstream-commit )"
    fi
  fi

  # Community patches
  if [[ "$(realpath -Lm . 2>&1)" =~ -Lm ]]; then
    warning "Detected non-GNU realpath (busybox?), please disable community patches in case of issues"
  else
    _realpath_arg="-Lm"
  fi

  if [ -n "$_community_patches" ]
  then
    _community_patches_repo_roots=()

    for _p in "../.." ".." "."
    do
      _new_path="$(realpath $_realpath_arg "${_where}/${_p}/community-patches")"

      if [[ ${#_community_patches_repo_roots[@]} -eq 0 ]] || [[ ! ${_new_path} == ${_community_patches_repo_roots[${#_community_patches_repo_roots[@]}-1]} ]]
      then
        _community_patches_repo_roots+=( "${_new_path}" )
      fi
    done

    for _p in "${_community_patches_repo_roots[@]}"
    do
      if [[ -d ${_p} ]]
      then
        msg2 "Using '${_p}' as community-patches repo root"
        _community_patches_repo_path="${_p}/wine-tkg-git"
        break
      fi
    done

    if [[ -z ${_community_patches_repo_path} ]]
    then
      unset _clone_failed

      for _p in "${_community_patches_repo_roots[@]}"
      do
        if [ -z "${_clone_failed}" ]
        then
          msg2 "Cloning community-patches repo into \'${_p}\'..."
        else
          msg2 "Retrying into \'${_p}\'..."
        fi

        if git clone https://github.com/Frogging-Family/community-patches.git "${_p}"
        then
          unset _clone_failed
          _community_patches_repo_path="${_p}/wine-tkg-git"
          break
        else
          _clone_failed=1
        fi
      done

      if [[ -n "${_clone_failed}" ]]
      then
        error "Error while attempting to clone community-patches repo"
        exit 1
      fi
    elif [[ "${_community_patches_auto_update}" != "false" ]]
    then
      msg2 "Updating community-patches repo..."

      if ! git -C "${_community_patches_repo_path}" pull origin master
      then
        error "Error while updating community-patches repo"
        exit 1
      fi
    fi

    _community_patches=($_community_patches)

    for _p in ${_community_patches[@]}
    do
      if [ -e "$_community_patches_repo_path/$_p" ]
      then
        ln -s "$_community_patches_repo_path/$_p" "$_where"/
      else
        warning "The requested community patch \"$_p\" wasn't found in the community-patches repo."
        msg2 "You can check https://github.com/Frogging-Family/community-patches.git for available patches."
        msg2 ""
        msg2 "Press enter to continue."
        read -r
      fi
    done
  fi

	# output config to logfile
	echo "# Last $pkgname configuration - $(date) :" > "$_where"/last_build_config.log
	echo "" >> "$_where"/last_build_config.log

	# log config file in use
	if [ -n "$_LOCAL_PRESET" ] && [ -e "$_where"/wine-tkg-profiles/wine-tkg-"$_LOCAL_PRESET".cfg ]; then
	  _cfgstringin="$_LOCAL_PRESET" && _cfgstring && echo "Local preset configuration file $_cfgstringout used" >> "$_where"/last_build_config.log
	elif [ -n "$_EXT_CONFIG_PATH" ] && [ -e "$_EXT_CONFIG_PATH" ]; then
	  _cfgstringin="$_EXT_CONFIG_PATH" && _cfgstring && echo "External configuration file $_cfgstringout used" >> "$_where"/last_build_config.log
	else
	  echo "Local cfg files used" >> "$_where"/last_build_config.log
	fi

	if [ "$_nomakepkg_midbuild_prompt" = "true" ]; then
	  echo "You will be prompted after the 64-bit side is built (compat workaround)" >> "$_where"/last_build_config.log
	fi

	_realwineversion=$(_describe_wine)
	echo "" >> "$_where"/last_build_config.log
	echo "Wine (plain) version: $_realwineversion" >> "$_where"/last_build_config.log

	if [ "$_use_staging" = "true" ]; then
	  cd "${srcdir}"/"${_stgsrcdir}"
	  _realwineversion=$(_describe_wine)
	  echo "Using wine-staging patchset (version $_realwineversion)" >> "$_where"/last_build_config.log
	  cd "${srcdir}"/"${_winesrcdir}"
	fi

	echo "" >> "$_where"/last_build_config.log
	echo -e "*.patch\n*.orig\n*~\n.gitignore\nautom4te.cache/*" > "${srcdir}"/"${_winesrcdir}"/.gitignore

	# Disable local Esync on 553986f
	if [ "$_use_staging" = "true" ]; then
	  cd "${srcdir}"/"${_stgsrcdir}"
	  if git merge-base --is-ancestor 553986fdfb111914f793ff1487d53af022e4be19 HEAD; then # eventfd_synchronization: Add patch set.
	    _use_esync="false"
	    _staging_esync="true"
	    echo "Disabled the local Esync patchset to use Staging impl instead." >> "$_where"/last_build_config.log
	  fi
	  cd "${srcdir}"/"${_winesrcdir}"
	fi

	if [ "$_use_esync" = "true" ]; then
	  if [ -z "$_esync_version" ]; then
	    if git merge-base --is-ancestor 2600ecd4edfdb71097105c74312f83845305a4f2 HEAD; then # 3.20+
	      _esync_version="ce79346"
	    elif git merge-base --is-ancestor aec7befb5115d866724149bbc5576c7259fef820 HEAD; then # 3.19-3.17
	      _esync_version="b4478b7"
	    else
	      _esync_version="5898a69" # 3.16 and lower
	    fi
	  fi
	  echo "Using esync patchset (version ${_esync_version})" >> "$_where"/last_build_config.log
	  wget -O "$_where"/esync"${_esync_version}".tgz https://github.com/zfigura/wine/releases/download/esync"${_esync_version}"/esync.tgz && tar zxf "$_where"/esync"${_esync_version}".tgz -C "${srcdir}"
	fi

	if [ "$_use_pba" = "true" ]; then
	  # If using a wine version that includes 944e92b, disable PBA
	  if git merge-base --is-ancestor 944e92ba06ecadeb933d95e30035323483dfe7c7 HEAD; then # wined3d: Pass the wined3d_buffer_desc structure directly to buffer_init()
	    _pba_version="none"
	  # If using a wine version that includes 580ea44, apply 3.17+ fixes
	  elif git merge-base --is-ancestor 580ea44bc65472c0304d74b7e873acfb7f680b85 HEAD; then # wined3d: Use query buffer objects for occlusion queries
	    _pba_version="317+"
	  # If using a wine version that includes cf9536b, apply 3.14+ fixes
	  elif git merge-base --is-ancestor cf9536b6bfbefbf5003c7633446a91f6e399c4de HEAD; then # wined3d: Move OpenGL initialisation code to adapter_gl.c
	    _pba_version="314+"
	  else
	    _pba_version="313-"
	  fi
	fi

	if [ "$_use_legacy_gallium_nine" = "true" ]; then
	  echo "Using gallium nine patchset (legacy)" >> "$_where"/last_build_config.log
	fi

	if [ "$_use_vkd3dlib" != "true" ]; then
	  echo "Not using vkd3d native library for d3d12 translation (allows using vkd3d-proton)" >> "$_where"/last_build_config.log
	fi

	# mingw-w64-gcc
	if [ "$_NOMINGW" = "true" ]; then
	  echo "Not using MinGW-gcc for building" >> "$_where"/last_build_config.log
	fi

	echo "" >> "$_where"/last_build_config.log

	if [ "$_NUKR" = "debug" ]; then
	  msg2 "You are currently in debug/dev mode. By default, patches aren't applied in this mode as the source won't be cleaned up/reset between compilations. You can however choose to patch your tree to get your initial source as you desire:"
	  read -rp "Do you want to patch the current wine source with the builtin patches (respecting your .cfg settings)? Do it only once or patches will fail!"$'\n> N/y : ' _DEBUGANSW1;
	  if [ "$_use_staging" = "true" ]; then
	    read -rp "Do you want to patch the current wine source with staging patches (respecting your .cfg settings)? Do it only once or patches will fail!"$'\n> N/y : ' _DEBUGANSW2;
	  fi
	  read -rp "Do you want to run configure? You need to run it at least once to populate your build dirs!"$'\n> N/y : ' _DEBUGANSW3;
	fi

	# Reverts
	nonuser_reverter() {
	  if [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW1" =~ [yY] ]]; then
	    if git merge-base --is-ancestor $_committorevert HEAD; then
	      echo -e "\n$_committorevert reverted $_hotfixmsg" >> "$_where"/prepare.log
	      git revert -n --no-edit $_committorevert >> "$_where"/prepare.log || (error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience."; msg2 "To use the last known good mainline version, please set _plain_version=\"$_last_known_good_mainline\" in your .cfg"; msg2 "To use the last known good staging version, please set _staging_version=\"$_last_known_good_staging\" in your .cfg (requires _use_staging=\"true\")" && exit 1)
	      if [ "$_hotfixmsg" != "(hotfix)" ] && [ "$_hotfixmsg" != "(staging hotfix)" ]; then
	        echo -e "$_committorevert reverted $_hotfixmsg" >> "$_where"/last_build_config.log
	      fi
	    fi
	  fi
	}

	# Backports
	nonuser_cherry_picker() {
	  if [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW1" =~ [yY] ]]; then
	    if ! git merge-base --is-ancestor $_committocherrypick HEAD; then
	      echo -e "\n$_committocherrypick cherry picked $_hotfixmsg" >> "$_where"/prepare.log
	      git cherry-pick -n --keep-redundant-commits $_committocherrypick >> "$_where"/prepare.log || (error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience." && exit 1)
	      if [ "$_hotfixmsg" != "(hotfix)" ] && [ "$_hotfixmsg" != "(staging hotfix)" ]; then
	        echo -e "$_committocherrypick cherry picked $_hotfixmsg" >> "$_where"/last_build_config.log
	      fi
	    fi
	  fi
	}

	# Hotfixer
	if [ "$_LOCAL_PRESET" != "staging" ] && [ "$_LOCAL_PRESET" != "mainline" ] && [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW1" =~ [yY] ]]; then
	  source "$_where"/wine-tkg-patches/hotfixes/hotfixer
	  msg2 "cherry picking..."
	  for _commit in ${_hotfix_mainlinebackports[@]}; do
	    cd "${srcdir}"/"${_winesrcdir}"
	    _committocherrypick=$_commit _hotfixmsg="(hotfix)" nonuser_cherry_picker
	    cd "${srcdir}"/"${_winesrcdir}"
	  done
	  echo -e "Done applying backports hotfixes (if any) - list available in prepare.log" >> "$_where"/last_build_config.log
	  msg2 "Hotfixing..."
	  for _commit in ${_hotfix_mainlinereverts[@]}; do
	    cd "${srcdir}"/"${_winesrcdir}"
	    _committorevert=$_commit _hotfixmsg="(hotfix)" nonuser_reverter
	    cd "${srcdir}"/"${_winesrcdir}"
	  done
	  for _commit in ${_hotfix_stagingreverts[@]}; do
	    cd "${srcdir}"/"${_stgsrcdir}"
	    _committorevert=$_commit _hotfixmsg="(staging hotfix)" nonuser_reverter
	    cd "${srcdir}"/"${_winesrcdir}"
	  done
	  echo -e "Done applying reverting hotfixes (if any) - list available in prepare.log" >> "$_where"/last_build_config.log
	fi

	echo "" >> "$_where"/last_build_config.log

	if [ "$_unfrog" != "true" ]; then
	  source "$_where"/wine-tkg-patches/reverts
	fi

	_commitmsg="01-reverts" _committer

	# Don't include *.orig and *~ files in the generated staging patchsets
	if [ "$_generate_patchsets" != "false" ] && [ "$_use_staging" = "true" ]; then
	  echo -e "*.orig\n*~" >> "${srcdir}"/"${_stgsrcdir}"/.gitignore
	  _commitmsg="gitignore" _committer
	fi

	# Hotfixer-staging
	if [ "$_NUKR" != "debug" ] && [ "$_unfrog" != "true" ] || [[ "$_DEBUGANSW2" =~ [yY] ]]; then
	  if [ "$_use_staging" = "true" ]; then
	    if [ "$_LOCAL_PRESET" != "staging" ] && [ "$_LOCAL_PRESET" != "mainline" ]; then
	      cd "${srcdir}"/"${_stgsrcdir}"
	      _userpatch_target="wine-staging" _userpatch_ext="earlystaging" hotfixer
	      _userpatch_target="wine-staging" _userpatch_ext="mystaging" hotfixer
	      _commitmsg="01-staging-hotfixes" _committer
	      cd "${srcdir}"/"${_winesrcdir}"
	    fi
	  fi
	fi

	# Hotfixer early mainline
	if [ "$_NUKR" != "debug" ] && [ "$_unfrog" != "true" ] || [[ "$_DEBUGANSW1" =~ [yY] ]]; then
	  if [ "$_LOCAL_PRESET" != "staging" ] && [ "$_LOCAL_PRESET" != "mainline" ]; then
	    _userpatch_target="wine-mainline" _userpatch_ext="myearly" hotfixer
	  fi
	fi

	# wine-staging user patches
	if [ "$_user_patches" = "true" ]; then
	  _userpatch_target="wine-staging"
	  _userpatch_ext="mystaging"
	  cd "${srcdir}"/"${_stgsrcdir}"
	  user_patcher
	  cd "${srcdir}"/"${_winesrcdir}"
	fi

	if [ "$_unfrog" != "true" ]; then
	  source "$_where"/wine-tkg-patches/staging_fixes
	fi

	# Update winevulkan
	if [ "$_update_winevulkan" = "true" ] && ! git merge-base --is-ancestor 3e4189e3ada939ff3873c6d76b17fb4b858330a8 HEAD && git merge-base --is-ancestor eb39d3dbcac7a8d9c17211ab358cda4b7e07708a HEAD; then
	  _patchname='winevulkan-1.1.103.patch' && _patchmsg="Applied winevulkan 1.1.103 patch" && nonuser_patcher
	fi

    source "$_where"/wine-tkg-patches/misc/plasma_systray_fix/plasma_systray_fix
    source "$_where"/wine-tkg-patches/proton/valve_proton_fullscreen_hack/FS_bypass_compositor
    source "$_where"/wine-tkg-patches/misc/faudio-exp/faudio-exp
    source "$_where"/wine-tkg-patches/game-specific/poe-fix/poe-fix
    source "$_where"/wine-tkg-patches/game-specific/warframe-launcher/warframe-launcher
    source "$_where"/wine-tkg-patches/game-specific/f4skyrimse-fix/f4skyrimse-fix
    source "$_where"/wine-tkg-patches/game-specific/mtga/mtga-legacy
    source "$_where"/wine-tkg-patches/game-specific/sims_3-oldnvidia/sims_3-oldnvidia
    source "$_where"/wine-tkg-patches/game-specific/mwo/mwo
    source "$_where"/wine-tkg-patches/game-specific/resident_evil_4_hack/resident_evil_4_hack
    source "$_where"/wine-tkg-patches/misc/childwindow/childwindow
    source "$_where"/wine-tkg-patches/misc/0001-kernelbase-Remove-DECLSPEC_HOTPATCH-from-SetThreadSt/0001-kernelbase-Remove-DECLSPEC_HOTPATCH-from-SetThreadSt
    source "$_where"/wine-tkg-patches/misc/usvfs/usvfs

	# Reverts c6b6935 due to https://bugs.winehq.org/show_bug.cgi?id=47752
	if [ "$_c6b6935_revert" = "true" ] && ! git merge-base --is-ancestor cb703739e5c138e3beffab321b84edb129156000 HEAD; then
	  _patchname='revert-c6b6935.patch' && _patchmsg="Reverted c6b6935 to fix regression affecting performance negatively" && nonuser_patcher
	fi

    source "$_where"/wine-tkg-patches/misc/steam/steam
    source "$_where"/wine-tkg-patches/misc/CSMT-toggle/CSMT-toggle

	_commitmsg="02-pre-staging" _committer

	# Staging
	if [ "$_use_staging" = "true" ] && [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW2" =~ [yY] ]]; then
	  # We're converting our array to string to allow manipulation
	  if ( cd "${srcdir}"/"${_stgsrcdir}" && ! git merge-base --is-ancestor b8ca0eae9f47491ba257c422a2bc03fc37d13c22 HEAD ) || [ ! -d "${srcdir}"/"${_stgsrcdir}"/patches/ntdll-NtAlertThreadByThreadId ]; then
	    _staging_args=$( printf "%s" "${_staging_args[*]}" | sed 's/-W ntdll-NtAlertThreadByThreadId // ; s/ -W ntdll-NtAlertThreadByThreadId// ; s/-W ntdll-NtAlertThreadByThreadId//' )
	  else
	    _staging_args=$( printf "%s" "${_staging_args[*]}" )
	  fi
	  msg2 "Applying wine-staging patches... \n     Staging overrides used, if any: ${_staging_args}" && echo -e "\nStaging overrides, if any: ${_staging_args}\n" >> "$_where"/last_build_config.log && echo -e "\nApplying wine-staging patches..." >> "$_where"/prepare.log
	  "${srcdir}"/"${_stgsrcdir}"/patches/patchinstall.sh DESTDIR="${srcdir}/${_winesrcdir}" --all $_staging_args >> "$_where"/prepare.log 2>&1 || (error "Patch application has failed. The error was logged to $_where/prepare.log for your convenience."; msg2 "To use the last known good mainline version, please set _plain_version=\"$_last_known_good_mainline\" in your .cfg"; msg2 "To use the last known good staging version, please set _staging_version=\"$_last_known_good_staging\" in your .cfg (requires _use_staging=\"true\")" && exit 1)

	  # Remove staging version tag
	  sed -i "s/  (Staging)//g" "${srcdir}"/"${_winesrcdir}"/libs/wine/Makefile.in
	  _commitmsg="03-staging" _committer
	fi

	# Manual staging patches application on top of proton valve trees
	if [[ "$_custom_wine_source" = *"ValveSoftware"* ]] && [ "$_use_staging" = "true" ]; then
	  _proton_staging
	  if [ "$_use_GE_patches" = "true" ]; then
	    _GE
	  fi
	fi

    source "$_where"/wine-tkg-patches/proton/use_clock_monotonic/use_clock_monotonic
    source "$_where"/wine-tkg-patches/proton/esync/esync
    source "$_where"/wine-tkg-patches/misc/launch-with-dedicated-gpu-desktop-entry/launch-with-dedicated-gpu-desktop-entry
    source "$_where"/wine-tkg-patches/misc/lowlatency_audio/lowlatency_audio
    source "$_where"/wine-tkg-patches/game-specific/sims_2-fix/sims_2-fix
    source "$_where"/wine-tkg-patches/misc/pythonfix/pythonfix
    source "$_where"/wine-tkg-patches/misc/high-core-count-fix/high-core-count-fix
    source "$_where"/wine-tkg-patches/game-specific/ffxiv-launcher-workaround/ffxiv-launcher-workaround
    source "$_where"/wine-tkg-patches/game-specific/leagueoflolfix/leagueoflolfix
    source "$_where"/wine-tkg-patches/game-specific/assettocorsa_hud_perf/assettocorsa_hud_perf
    source "$_where"/wine-tkg-patches/game-specific/mk11/mk11
    source "$_where"/wine-tkg-patches/misc/PBA/PBA

	# d3d9 patches
	if [ "$_use_legacy_gallium_nine" = "true" ] && [ "$_use_staging" = "true" ] && ! git merge-base --is-ancestor e24b16247d156542b209ae1d08e2c366eee3071a HEAD; then
	  wget -O "$_where"/wine-d3d9.patch https://raw.githubusercontent.com/sarnex/wine-d3d9-patches/master/wine-d3d9.patch
	  wget -O "$_where"/staging-helper.patch https://raw.githubusercontent.com/sarnex/wine-d3d9-patches/master/staging-helper.patch
	  patch -Np1 < "$_where"/staging-helper.patch
	  patch -Np1 < "$_where"/wine-d3d9.patch
	  autoreconf -f
	elif [ "$_use_legacy_gallium_nine" = "true" ] && [ "$_use_staging" != "true" ] && ! git merge-base --is-ancestor e24b16247d156542b209ae1d08e2c366eee3071a HEAD; then
	  wget -O "$_where"/wine-d3d9.patch https://raw.githubusercontent.com/sarnex/wine-d3d9-patches/master/wine-d3d9.patch
	  wget -O "$_where"/d3d9-helper.patch https://raw.githubusercontent.com/sarnex/wine-d3d9-patches/master/d3d9-helper.patch
	  patch -Np1 < "$_where"/d3d9-helper.patch
	  patch -Np1 < "$_where"/wine-d3d9.patch
	  autoreconf -f
	elif [ "$_use_legacy_gallium_nine" = "true" ] && git merge-base --is-ancestor e24b16247d156542b209ae1d08e2c366eee3071a HEAD; then
	  echo "Legacy Gallium Nine disabled due to known issues with selected Wine version" >> "$_where"/last_build_config.log
	fi

    source "$_where"/wine-tkg-patches/misc/GLSL-toggle/GLSL-toggle
    source "$_where"/wine-tkg-patches/misc/virtual_desktop_refreshrate/virtual_desktop_refreshrate
    source "$_where"/wine-tkg-patches/proton/fsync/fsync

	echo -e "" >> "$_where"/last_build_config.log

    source "$_where"/wine-tkg-patches/proton/valve_proton_fullscreen_hack/valve_proton_fullscreen_hack
    source "$_where"/wine-tkg-patches/misc/childwindow/childwindow-proton
    source "$_where"/wine-tkg-patches/proton/shared-gpu-resources/shared-gpu-resources
    source "$_where"/wine-tkg-patches/proton/proton-rawinput/proton-rawinput
    source "$_where"/wine-tkg-patches/misc/winevulkan/winevulkan
    source "$_where"/wine-tkg-patches/game-specific/overwatch-mfstub/overwatch-mfstub
    source "$_where"/wine-tkg-patches/game-specific/mtga/mtga
    source "$_where"/wine-tkg-patches/proton/proton_mf_hacks/proton_mf_hacks
    source "$_where"/wine-tkg-patches/misc/enable_stg_shared_mem_def/enable_stg_shared_mem_def
    source "$_where"/wine-tkg-patches/misc/nvidia-hate/nvidia-hate
    source "$_where"/wine-tkg-patches/misc/kernelbase-reverts/kernelbase-reverts
    source "$_where"/wine-tkg-patches/proton/LAA/LAA
    source "$_where"/wine-tkg-patches/proton-tkg-specific/proton-staging/proton-staging_winex11-MWM_Decorations
    source "$_where"/wine-tkg-patches/proton-tkg-specific/proton-tkg-steamclient-swap/proton-tkg-steamclient-swap

	echo -e "" >> "$_where"/last_build_config.log

	# Set mono version and hash for proton
	if [ "$_EXTERNAL_INSTALL" = "proton" ] && [ "$_unfrog" != "true" ]; then
	  if [ "$_use_latest_mono" = "true" ]; then
	    mono_ver=$( ls "$_where"/wine-mono* | sed -e "s|.*wine-mono-||; s/-x86.msi//" )
	    mono_sum=$( echo $( sha256sum "$_where"/wine-mono* | cut -d " " -f 1 ) )
	    echo -e "Setting wine-mono version to ${mono_ver} with sha256 ${mono_sum}" >> "$_where"/last_build_config.log
	    sed -i "s|#define MONO_VERSION.*|#define MONO_VERSION \"${mono_ver}\"|g" "${srcdir}"/"${_winesrcdir}"/dlls/appwiz.cpl/addons.c
	    sed -i "s|#define MONO_SHA.*|#define MONO_SHA \"${mono_sum}\"|g" "${srcdir}"/"${_winesrcdir}"/dlls/appwiz.cpl/addons.c
	    sed -i "s|#define WINE_MONO_VERSION.*|#define WINE_MONO_VERSION \"${mono_ver}\"|g" "${srcdir}"/"${_winesrcdir}"/dlls/mscoree/mscoree_private.h
	  fi
	fi

    source "$_where"/wine-tkg-patches/proton-tkg-specific/proton-tkg/proton-tkg

	# Proton RDR2 fixes from Paul Gofman - Bound to the "Protonify the staging syscall emu" hotfix
	# The legacy patch is found in proton meta patchsets, and was moved here for more flexibility following the recent ntdll changes
	if [ "$_use_staging" = "true" ] && [ -e "$_where"/rdr2.patch ]; then
	  _patchname='rdr2.patch' && _patchmsg="Enable Proton's RDR2 fixes from Paul Gofman" && nonuser_patcher
	fi

    source "$_where"/wine-tkg-patches/game-specific/quake_champions_fix/quake_champions_fix
    source "$_where"/wine-tkg-patches/proton-tkg-specific/proton-cpu-topology-overrides/proton-cpu-topology-overrides
    source "$_where"/wine-tkg-patches/misc/fastsync/fastsync
    source "$_where"/wine-tkg-patches/proton-tkg-specific/proton-sdl-joy/proton-sdl-joy

	if [ "$_EXTERNAL_INSTALL" = "proton" ] && [ "$_unfrog" != "true" ] || [ "$_steamvr_support" = "true" ]; then
	  #source "$_where"/proton-restore-unicode
	  source "$_where"/wine-tkg-patches/proton-tkg-specific/proton-wined3d-additions/proton-wined3d-additions
	  source "$_where"/wine-tkg-patches/proton-tkg-specific/proton-vr/proton-vr
	fi

    source "$_where"/wine-tkg-patches/proton-tkg-specific/proton-vk-bits-4.5/proton-vk-bits-4.5
    source "$_where"/wine-tkg-patches/proton/msvcrt_nativebuiltin/msvcrt_nativebuiltin
    source "$_where"/wine-tkg-patches/proton/proton-bcrypt/proton-bcrypt
    source "$_where"/wine-tkg-patches/misc/josh-flat-theme/josh-flat-theme
    source "$_where"/wine-tkg-patches/proton/proton-win10-default/proton-win10-default
    source "$_where"/wine-tkg-patches/proton/dxvk_config/dxvk_config
    source "$_where"/wine-tkg-patches/proton-tkg-specific/proton_battleye/proton_battleye
    source "$_where"/wine-tkg-patches/proton-tkg-specific/proton_eac/proton_eac

	# Proton-tkg needs to know if standard dlopen() is in use
	if ( cd "${srcdir}"/"${_winesrcdir}" && git merge-base --is-ancestor b87256cd1db21a59484248a193b6ad12ca2853ca HEAD ); then
	  _standard_dlopen="true"
	else
	  _standard_dlopen="false"
	fi

	if [[ "$_custom_wine_source" != *"ValveSoftware"* ]] && ( cd "${srcdir}"/"${_winesrcdir}" && git merge-base --is-ancestor ce91ef6426bf5065bd31bb82fa4f76011e7a9a36 HEAD ); then
	  _processinfoclass="true"
	fi

	echo -e "" >> "$_where"/last_build_config.log
	_commitmsg="04-post-staging" _committer
}

_polish() {
	# wine user patches
	_userpatch_target="plain-wine"
	_userpatch_ext="my"
	cd "${srcdir}"/"${_winesrcdir}"
	if [ "$_NUKR" != "debug" ] && [ "$_unfrog" != "true" ] || [[ "$_DEBUGANSW1" =~ [yY] ]]; then
	  if [ "$_LOCAL_PRESET" != "staging" ] && [ "$_LOCAL_PRESET" != "mainline" ] && [ -z "$_localbuild" ]; then
	    hotfixer && _commitmsg="05-hotfixes" _committer
	  fi
	fi
	if [ "$_user_patches" = "true" ]; then
	  user_patcher && _commitmsg="06-userpatches" _committer
	fi

	# UNFROG HOTFIX - Autoconf 2.70 fix for legacy trees - https://github.com/wine-mirror/wine/commit/d7645b67c350f7179a1eba749ec4524c74948d86
	if [ "$_unfrog" = "true" ] && ( cd "${srcdir}"/"${_winesrcdir}" && ! git merge-base --is-ancestor d7645b67c350f7179a1eba749ec4524c74948d86 HEAD ); then
	  patch -Np1 < "$_where"/wine-tkg-patches/hotfixes/autoconf-legacy-fix/autoconf-legacy-fix.mypatch
	fi

	echo "" >> "$_where"/last_build_config.log

	source "$_where"/wine-tkg-patches/misc/wine-tkg/wine-tkg

	# tools/make_makefiles destroys Valve trees - disable on those
	if [[ "$_custom_wine_source" != *"ValveSoftware"* ]]; then
	  git add * && true
	  tools/make_makefiles
	fi

	echo -e "\nRunning make_vulkan" >> "$_where"/prepare.log && dlls/winevulkan/make_vulkan >> "$_where"/prepare.log 2>&1
	tools/make_requests
	autoreconf -fiv

	# wine late user patches - Applied after make_vulkan/make_requests/autoreconf
	_userpatch_target="plain-wine"
	_userpatch_ext="mylate"
	cd "${srcdir}"/"${_winesrcdir}"
	if [ "$_user_patches" = "true" ]; then
	  user_patcher && _commitmsg="07-late-userpatches" _committer
	fi

	# Get rid of temp patches
	rm -rf "$_where"/*.patch
	rm -rf "$_where"/*.my*
	rm -rf "$_where"/*.orig

	# The versioning string has moved with 1dd3051cca5cafe90ce44460731df61abb680b3b
	# Since this is reverted by the hotfixer path, only use the new path on 0c249e6+ (deprecation of the hotfixer path)
	if ( cd "${srcdir}"/"${_winesrcdir}" && ! git merge-base --is-ancestor 0c249e6125fc9dc6ee86b4ef6ae0d9fa2fc6291b HEAD ); then
	  _versioning_path="${srcdir}/${_winesrcdir}/libs/wine/Makefile.in"
	  _versioning_string="top_srcdir"
	elif ( cd "${srcdir}"/"${_winesrcdir}" && git merge-base --is-ancestor c6b5f4a406351e7faef33de23d64db4445ef9aea HEAD ); then
	  _versioning_path="${srcdir}/${_winesrcdir}/configure.ac"
	  _versioning_string="wine_srcdir"
	else
	  _versioning_path="${srcdir}/${_winesrcdir}/Makefile.in"
	  _versioning_string="srcdir"
	fi

	if [ -n "$_localbuild" ] && [ -n "$_localbuild_versionoverride" ]; then
	  if [ "$_versioning_string" = "wine_srcdir" ]; then
	    sed -i "s/GIT_DIR=\${$_versioning_string}.git git describe HEAD 2>\\/dev\\/null || echo \\\\\"wine-\\\\\$(PACKAGE_VERSION)\\\\\"/echo \\\\\"wine-$_localbuild_versionoverride\\\\\"/g" "$_versioning_path"
	  else
	    sed -i "s/GIT_DIR=\$($_versioning_string)\\/.git git describe HEAD 2>\\/dev\\/null || echo \"wine-\$(PACKAGE_VERSION)\"/echo \"wine-$_localbuild_versionoverride\"/g" "$_versioning_path"
	  fi
	elif [ -z "$_localbuild" ]; then
	  # Set custom version so that it reports the same as pkgver
	  if [ "$_versioning_string" = "wine_srcdir" ]; then
	    sed -i "s/GIT_DIR=\${$_versioning_string}.git git describe HEAD 2>\\/dev\\/null || echo \\\\\"wine-\\\\\$(PACKAGE_VERSION)\\\\\"/echo \\\\\"wine-$_realwineversion\\\\\"/g" "$_versioning_path"
	    if [ -e "${srcdir}/${_winesrcdir}/configure" ]; then
	      sed -i "s/GIT_DIR=\${$_versioning_string}.git git describe HEAD 2>\\/dev\\/null || echo \\\\\"wine-\\\\\$(PACKAGE_VERSION)\\\\\"/echo \\\\\"wine-$_realwineversion\\\\\"/g" "${srcdir}/${_winesrcdir}/configure"
	    fi
	  else
	    sed -i "s/GIT_DIR=\$($_versioning_string)\\/.git git describe HEAD 2>\\/dev\\/null || echo \"wine-\$(PACKAGE_VERSION)\"/echo \"wine-$_realwineversion\"/g" "$_versioning_path"
	  fi

	  # Set custom version tags
	  local _version_tags=()
	  _version_tags+=(TkG) # watermark to keep track of TkG builds independently of the settings
	  if [ "$_use_staging" = "true" ]; then
	    _version_tags+=(Staging)
	  else
	    _version_tags+=(Plain)
	  fi
	  if [ "$_use_esync" = "true" ] || [ "$_staging_esync" = "true" ] && [[ "$_custom_wine_source" != *"ValveSoftware"* ]]; then
	   _version_tags+=(Esync)
	  fi
	  if [ "$_use_fsync" = "true" ] && [ "$_staging_esync" = "true" ] && [[ "$_custom_wine_source" != *"ValveSoftware"* ]]; then
	    _version_tags+=(Fsync)
	  fi
	  if [ "$_use_pba" = "true" ] && [ "$_pba_version" != "none" ] && [[ "$_custom_wine_source" != *"ValveSoftware"* ]]; then
	    _version_tags+=(PBA)
	  fi
	  if [ "$_use_legacy_gallium_nine" = "true" ]; then
	    _version_tags+=(Nine)
	  fi
	  if [ "$_use_vkd3dlib" = "false" ]; then
	    if [ "$_dxvk_dxgi" != "true" ] && git merge-base --is-ancestor 74dc0c5df9c3094352caedda8ebe14ed2dfd615e HEAD; then
	      _version_tags+=(Vkd3d DXVK-Compatible)
	    fi
	  fi
	  if [ "$_versioning_string" = "wine_srcdir" ]; then
	    sed -i "s/\\\\\"\\\\\\\1.*\"/\\\\\"\\\\\\\1  ( ${_version_tags[*]} )\\\\\"/g" "${_versioning_path}"
	    sed -i "s/\\\\\"\\\\\\\1.*\"/\\\\\"\\\\\\\1  ( ${_version_tags[*]} )\\\\\"/g" "${srcdir}/${_winesrcdir}/configure"
	  else
	    sed -i "s/\"\\\1.*\"/\"\\\1  ( ${_version_tags[*]} )\"/g" "${_versioning_path}"
	  fi
	  sed -i "s/\"\\\1.*\"/\"\\\1  ( ${_version_tags[*]} )\"/g" "${srcdir}"/"${_winesrcdir}"/dlls/ntdll/Makefile.in
	fi

	# Fix libldap detection on Arch
	if [ -e /usr/bin/pacman ]; then
	  if pacman -Qq libldap &> /dev/null; then
	    sed -i "s|-lldap_r|-lldap|" "$srcdir/$_winesrcdir/configure"
	  fi
	fi

	_commitmsg="07-tags-n-polish" _committer

	if [ "$_NUKR" != "debug" ]; then
	  # delete old build dirs (from previous builds)
	  rm -rf "${srcdir}"/wine-tkg-*-{32,64}-build
	fi

	# no compilation
	if [ "$_NOCOMPILE" = "true" ]; then
	  cp -u "$_where"/last_build_config.log "${srcdir}"/"${_winesrcdir}"/wine-tkg-config.txt
	fi

	cd "$_where" # this is needed on version update not to get lost in srcdir
}

_makedirs() {
	# Nuke if present then create new build dirs
	if [ "$_NUKR" = "true" ] && [ "$_SKIPBUILDING" != "true" ]; then
	  rm -rf "${srcdir}"/"${pkgname}"-64-build
	  rm -rf "${srcdir}"/"${pkgname}"-32-build
	fi
	mkdir -p "${srcdir}"/"${pkgname}"-64-build
	mkdir -p "${srcdir}"/"${pkgname}"-32-build
}

# Workaround
trap _exit_cleanup EXIT
