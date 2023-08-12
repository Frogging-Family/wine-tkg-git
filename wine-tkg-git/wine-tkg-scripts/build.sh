#!/bin/bash

_prebuild_common() {
	cd "${srcdir}"

	echo "" >> "$_where"/last_build_config.log

	# Use custom compiler paths if defined
	if [ -n "${CUSTOM_MINGW_PATH}" ] && [ -z "${CUSTOM_GCC_PATH}" ]; then
	  PATH=${PATH}:$( find "$CUSTOM_MINGW_PATH/" -maxdepth 1 -printf "%p:" || ( warning "Custom compiler path seems wrong.." && exit 1 ) )
	  echo -e "CUSTOM_MINGW_PATH = ${CUSTOM_MINGW_PATH##*/}" >> "$_where"/last_build_config.log #" Coloring confusion
	elif [ -n "${CUSTOM_GCC_PATH}" ] && [ -z "${CUSTOM_MINGW_PATH}" ]; then
	  PATH=$( find "$CUSTOM_GCC_PATH/" -maxdepth 1 -printf "%p:" || ( warning "Custom compiler path seems wrong.." && exit 1 ) )${PATH}
	  echo -e "CUSTOM_GCC_PATH = ${CUSTOM_GCC_PATH##*/}" >> "$_where"/last_build_config.log #" Coloring confusion
	elif [ -n "${CUSTOM_MINGW_PATH}" ] && [ -n "${CUSTOM_GCC_PATH}" ]; then
	  PATH=$( find "$CUSTOM_GCC_PATH/" -maxdepth 1 -printf "%p:" || ( warning "Custom compiler path seems wrong.." && exit 1 ) )$( find "$CUSTOM_MINGW_PATH/" -maxdepth 1 -printf "%p:" || ( warning "Custom compiler path seems wrong.." && exit 1 ) )${PATH}
	  echo -e "CUSTOM_MINGW_PATH = ${CUSTOM_MINGW_PATH##*/}" >> "$_where"/last_build_config.log #" Coloring confusion
	  echo -e "CUSTOM_GCC_PATH = ${CUSTOM_GCC_PATH##*/}" >> "$_where"/last_build_config.log #"
	fi

	if [ "$_pkg_strip" != "true" ]; then
	  sed 's|${STRIPPROG-strip}||g' "$srcdir/$_winesrcdir"/tools/install-sh -i
	  echo "Stripping disabled" >> "$_where"/last_build_config.log
	fi

	echo "" >> "$_where"/last_build_config.log

	# compiler flags
	if [ "$_LOCAL_OPTIMIZED" = "true" ]; then
	  export CFLAGS="${_GCC_FLAGS}"
	  export CXXFLAGS="${_GCC_FLAGS}"
	  export LDFLAGS="${_LD_FLAGS}"
	  # Workaround for building legacy trees with mingw GCC11
	  if ( cd "${srcdir}"/"${_winesrcdir}" && ! git merge-base --is-ancestor 9008cd2f2437650ad41ce8a8924ed1828ca21889 HEAD ); then
	    export CROSSCFLAGS="${_CROSS_FLAGS} -fno-builtin-{sin,cos}{,f}"
	  else
	    export CROSSCFLAGS="${_CROSS_FLAGS}"
	  fi
	  export CROSSLDFLAGS="${_CROSS_LD_FLAGS}"
	  echo "With predefined optimizations:" >> "$_where"/last_build_config.log
	else
	  export CROSSCFLAGS="$(echo "$CFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/-fno-plt//" -e "s/-fstack-clash-protection//")"
	  export CROSSLDFLAGS="$(echo "$CFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/,-z,now//" -e "s/-fno-plt//")"
	  echo "Using /etc/makepkg.conf settings for compiler optimization flags" >> "$_where"/last_build_config.log
	fi

	# workaround for FS#55128
	# https://bugs.archlinux.org/task/55128
	# https://bugs.winehq.org/show_bug.cgi?id=43530
	export CFLAGS="$(echo "$CFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/-fno-plt//" -e "s/-fstack-clash-protection//")"
	export LDFLAGS="$(echo "$LDFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/,-z,now//" -e "s/-fno-plt//")"
	export CROSSCFLAGS="$(echo "$CROSSCFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/-fno-plt//" -e "s/-fstack-clash-protection//")"
	export CROSSLDFLAGS="$(echo "$CROSSLDFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/,-z,now//" -e "s/-fno-plt//")"
	echo "CFLAGS = ${CFLAGS}" >> "$_where"/last_build_config.log
	echo "LDFLAGS = ${LDFLAGS}" >> "$_where"/last_build_config.log
	echo "CROSSCFLAGS = ${CROSSCFLAGS}" >> "$_where"/last_build_config.log
	echo "CROSSLDFLAGS = ${CROSSLDFLAGS}" >> "$_where"/last_build_config.log

	if [ -z "$_localbuild" ]; then
	  # Disable tests by default, enable back with _enable_tests="true"
	  if [ "$_ENABLE_TESTS" != "true" ]; then
	    _configure_args+=(--disable-tests)
	  fi

	  if [ "$_faudio_ignorecheck" != "true" ]; then
	    _configure_args+=(--with-faudio)
	  fi

	  if [ "$_use_legacy_gallium_nine" = "true" ] && [ "$_use_staging" = "true" ] && ! git merge-base --is-ancestor e24b16247d156542b209ae1d08e2c366eee3071a HEAD; then
	    _configure_args+=(--with-d3d9-nine)
	  fi

	  if [ "$_use_vkd3dlib" != "true" ]; then
	    _configure_args+=(--without-vkd3d)
	  fi

	  # mingw-w64-gcc
	  if [ "$_NOMINGW" = "true" ]; then
	    _configure_args+=(--without-mingw)
	  fi

	  # Wayland driver
	  if [ "$_wayland_driver" = "true" ]; then
	    _configure_args64+=(--with-wayland --with-vulkan)
	    _configure_args32+=(--with-wayland --with-vulkan)
	  fi
	fi

	echo -e "\nconfigure arguments: ${_configure_args[@]}\n" >> "$_where"/last_build_config.log
}

_build_single_make() (
  export _LAST_BUILD_CONFIG="$_where"/last_build_config.log
  export _FROGMINER_VARFILE="$(mktemp)"
  trap 'rm -f -- "$_FROGMINER_VARFILE"' EXIT
  { ( unset MAKEFLAGS; unset MFLAGS; set ); echo; set +o; } >"$_FROGMINER_VARFILE"
  if [ "$_LOCAL_OPTIMIZED" = 'true' ]; then
    # make using all available threads
    if [ "$_log_errors_to_file" = "true" ]; then
      make -f "$_where"/wine-tkg-scripts/Makefile.single -j$(nproc) 2> "$_where/debug.log"
    else
      #_buildtime64=$( time ( make --jobserver-style=fifo -f "$_where"/wine-tkg-scripts/Makefile.single -j$(nproc) 2>&1 ) 3>&1 1>&2 2>&3 ) - Bash 5.2 is frogged - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1018727
      make -f "$_where"/wine-tkg-scripts/Makefile.single -j$(nproc)
    fi
  else
    # make using makepkg settings
    if [ "$_log_errors_to_file" = "true" ]; then
      make -f "$_where"/wine-tkg-scripts/Makefile.single 2> "$_where/debug.log"
    else
      #_buildtime64=$( time ( make -f "$_where"/wine-tkg-scripts/Makefile.single 2>&1 ) 3>&1 1>&2 2>&3 ) - Bash 5.2 is frogged - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1018727
      make -f "$_where"/wine-tkg-scripts/Makefile.single
    fi
  fi
)

_build_serial() {
  local _SINGLE_MAKE=false
  local _LAST_BUILD_CONFIG="$_where"/last_build_config.log
  . "$_where"/wine-tkg-scripts/build-64.sh
  . "$_where"/wine-tkg-scripts/build-32.sh
  if [ "$_NOLIB64" != "true" ]; then
    # build wine 64-bit
    # (according to the wine wiki, this 64-bit/32-bit building order is mandatory)
    _exports_64
    _configure_64
    _build_64
  fi
  if [ "$_NOLIB32" != "true" ] && [ "$_NOLIB32" != "wow64" ]; then
    # build wine 32-bit
    # nomakepkg
    if [ "$_nomakepkg_midbuild_prompt" = "true" ]; then
      msg2 '64-bit side has been built, 32-bit will follow.'
      msg2 'This is the time to install the 32-bit devel packages you might need.'
      read -rp "    When ready, press enter to continue.."
    fi
    if [ "$_nomakepkg_dep_resolution_distro" = "debuntu" ]; then
      _debuntu_32
    fi
    # /nomakepkg
    _exports_32
    _configure_32
    _build_32
    if [ "$_nomakepkg_dep_resolution_distro" = "debuntu" ] && [ "$_NOLIB64" != "true" ]; then # Install 64-bit deps back after 32-bit wine is built
      _debuntu_64
    fi
  fi
}

_build() {
  if [ "$_SINGLE_MAKE" = 'true' ] && [ "$_NOLIB32" != "true" ]; then
    warning "Using experimental single-make mode!"
    if [ "$_nomakepkg_dep_resolution_distro" = "debuntu" ]; then
      error "_SINGLE_MAKE is incompatible with debian/ubuntu"
      return 1
    fi
    if [ "$_nomakepkg_midbuild_prompt" = "true" ]; then
      error "_SINGLE_MAKE is incompatible with _nomakepkg_midbuild_prompt"
      return 1
    fi
    _build_single_make
  else
    _build_serial
  fi
}

_generate_debian_package() {
	_prefix="$1"

	msg2 'Generating a Debian package'
	"$_where"/wine-tkg-scripts/package-debian.sh "${pkgdir}" "${_prefix}" "${_where}" "${pkgname}-${pkgver}.deb" "${pkgver}" "${pkgname}"
}

_package_nomakepkg() {
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

	if [ "$_NOLIB32" = "true" ]; then
	  local _lib32name="lib"
	  local _lib64name="lib"
	elif [ -e /lib ] && [ -e /lib64 ] && [ -d /usr/lib ] && [ -d /usr/lib32 ] && [ "$_EXTERNAL_INSTALL" != "proton" ]; then
	  local _lib32name="lib32"
	  local _lib64name="lib"
	else
	  local _lib32name="lib"
	  local _lib64name="lib64"
	fi

	# External install
	if [ "$_EXTERNAL_INSTALL" = "true" ]; then
	  if [ "$_EXTERNAL_NOVER" = "true" ]; then
	    _prefix="$_DEFAULT_EXTERNAL_PATH/$pkgname"
	  else
	    # $_realwineversion doesn't carry over into the fakeroot environment
	    if [ "$_use_staging" = "true" ]; then
	      cd "$srcdir/$_stgsrcdir"
	    else
	      cd "$srcdir/$_winesrcdir"
	    fi
	    _realwineversion=$(_describe_wine)
	    _prefix="$_DEFAULT_EXTERNAL_PATH/$pkgname-$_realwineversion"
	  fi
	fi

	if [ "$_NOLIB32" = "false" ]; then
	  # package wine 32-bit
	  # (according to the wine wiki, this reverse 32-bit/64-bit packaging order is important)
	  msg2 'Packaging Wine-32...'
	  cd "${srcdir}/${pkgname}"-32-build
	  make install
	fi

	if [ "$_NOLIB64" != "true" ]; then
	  # package wine 64-bit
	  msg2 'Packaging Wine-64...'
	  cd "${srcdir}/${pkgname}"-64-build
	  make install
	fi

	if [ "$_MIME_NOPE" = "true" ]; then
	    sed 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' "$_prefix"/share/wine/wine.inf -i
	    msg2 'winemenubuilder.exe disabled'
	fi
	if [ "$_FOAS_NOPE" = "true" ]; then
	    sed 's|    LicenseInformation|    LicenseInformation,\\\n    FileOpenAssociations|g;$a \\n[FileOpenAssociations]\nHKCU,Software\\Wine\\FileOpenAssociations,"Enable",,"N"' "$_prefix"/share/wine/wine.inf -i
	    msg2 'FileOpenAssociations disabled'
	fi

	# wine-tkg path scripts - Might be useful for external builds when using weird env vars - Also workarounds wrong paths issues on non-Arch distros
	cp -v "$_where"/wine-tkg-scripts/wine-tkg "$_prefix"/bin/wine-tkg
	cp -v "$_where"/wine-tkg-scripts/wine64-tkg "$_prefix"/bin/wine64-tkg
	cp -v "$_where"/wine-tkg-scripts/wine-tkg-interactive "$_prefix"/bin/wine-tkg-interactive

	# Fixes compatibility with installation scripts (like winetricks) that use
	# the wine64 binary, which is not present in WoW64 builds.
	if [ "$_NOLIB32" = "wow64" ]; then
	    ( cd "$_prefix/bin" && ln -s wine wine64 )
	fi

	# strip
	if [ "$_EXTERNAL_INSTALL" != "proton" ]; then
	  if [ "$_protonify" = "true" ] && ( cd "${srcdir}"/"${_winesrcdir}" && ! git merge-base --is-ancestor 2e5e5ade82b5e3b1d70ebe6b1a824bdfdedfd04e HEAD ); then
	    if [ "$_pkg_strip" = "true" ]; then
	      msg2 "Fixing x86_64 PE files..."
	      find "$_prefix"/"$_lib64name"/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' ')' -printf '--strip-unneeded\0%p\0%p\0' | xargs -0 -r -P1 -n3 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
	      if [ "$_NOLIB32" != "true" ]; then
	        msg2 "Fixing i386 PE files..."
	        find "$_prefix"/"$_lib32name"/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' ')' -printf '--strip-unneeded\0%p\0%p\0' | xargs -0 -r -P1 -n3 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
		  fi
	      find "$_prefix"/bin/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' ')' -printf '--strip-unneeded\0%p\0%p\0' | xargs -0 -r -P1 -n3 sh -c 'objcopy --file-alignment=4096 "$@" > /dev/null 2>&1; exit 0' cmd
	    else
	      msg2 "Fixing x86_64 PE files..."
	      find "$_prefix"/"$_lib64name"/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' ')' -printf '%p\0%p\0' | xargs -0 -r -P1 -n2 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
	      if [ "$_NOLIB32" != "true" ]; then
	        msg2 "Fixing i386 PE files..."
	        find "$_prefix"/"$_lib32name"/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' ')' -printf '%p\0%p\0' | xargs -0 -r -P1 -n2 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
		  fi
	      find "$_prefix"/bin/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' ')' -printf '%p\0%p\0' | xargs -0 -r -P1 -n2 sh -c 'objcopy --file-alignment=4096 "$@" > /dev/null 2>&1; exit 0' cmd
	    fi
	  elif [ "$_pkg_strip" = "true" ]; then
	    for _f in $( find "$_prefix" -type f '(' -iname '*.dll' -or -iname '*.so' -or -iname '*.sys' -or -iname '*.drv' -or -iname '*.exe' ')' ); do
	      strip --strip-unneeded "$_f" && msg2 "$_f stripped"
	    done
	  fi
	fi

	cp -v "$_where"/last_build_config.log "$_prefix"/share/wine/wine-tkg-config.txt

	# move our build to some subfolder
	if [ -z "$_nomakepkg_prefix_path" ]; then
	  # if the target dir already exists, nuke it
	  rm -rf "$_where/non-makepkg-builds/${_nomakepkg_pkgname}"

	  mkdir -p "$_where"/non-makepkg-builds
	  mv "$_where/${_nomakepkg_pkgname}" "$_where"/non-makepkg-builds/
	  pkgdir="$_where/non-makepkg-builds/${_nomakepkg_pkgname}"
	else
	  pkgdir="${_nomakepkg_prefix_path}/${_nomakepkg_pkgname}"
	fi

	if [ "$_GENERATE_DEBIAN_PACKAGE" = "true" ] && [ "$_EXTERNAL_INSTALL" != "proton" ]; then
		_generate_debian_package "$_prefix"
	fi

	if [ "$_use_esync" = "true" ] || [ "$_staging_esync" = "true" ]; then
	  msg2 '##########################################################################################################################'
	  msg2 ''
	  msg2 'To enable esync, export WINEESYNC=1 and increase file descriptors limits in /etc/security/limits.conf to use ESYNC goodness ;)'
	  msg2 ''
	  msg2 'https://raw.githubusercontent.com/zfigura/wine/esync/README.esync'
	  msg2 ''
	  msg2 '##########################################################################################################################'
	  if [ "$_use_fsync" = "true" ]; then
	    msg2 '##########################################################################################################################'
	    msg2 ''
	    if [ "$_fsync_legacy" = "true" ]; then
	      msg2 'To enable fsync legacy, export WINEFSYNC=1 and use a linux54-tkg or newer. If no compatible kernel'
	      msg2 'is found and Esync is enabled, it will fallback to it. You can enable both to get a dynamic "failsafe" mechanism.'
	      msg2 ''
	      msg2 'https://steamcommunity.com/app/221410/discussions/0/3158631000006906163/'
	        if [ "$_fsync_futex2" = "true" ]; then
	          msg2 ''
	          msg2 'To enable fsync_futex2, additionally export WINEFSYNC_FUTEX2=1 and use a linux510-tkg or newer.'
	          msg2 ''
	          msg2 'https://github.com/ValveSoftware/Proton/issues/4568'
	        fi
	    else
	      msg2 'To enable fsync, export WINEFSYNC=1 and use a kernel 5.16+ (or at least linux513-tkg). If no compatible kernel'
	      msg2 'is found and Esync is enabled, it will fallback to it. You can enable both to get a dynamic "failsafe" mechanism.'
	      msg2 ''
	      msg2 'https://github.com/ValveSoftware/wine/pull/128'
	    fi
	    msg2 ''
	    msg2 '##########################################################################################################################'
	  fi
	fi

	# External install
	if [ "$_EXTERNAL_INSTALL" = "true" ]; then
	  msg2 "### This wine will be installed to: $_prefix"
	  msg2 "### Remember to use $_prefix/bin/wine instead of just wine (same for winecfg etc.)"
	elif [ "$_EXTERNAL_INSTALL" = "proton" ]; then
	  touch "${pkgdir}"/../HL3_confirmed
	else
	  if [ -e "$_where"/tarplz ];then
	    ( cd "$_where"/non-makepkg-builds && tar -cvf "${_nomakepkg_pkgname}".tar "${_nomakepkg_pkgname}" && rm -rf "${_nomakepkg_pkgname}" )
	  fi
	fi
}

_package_makepkg() {
	local _prefix=/usr
	local _lib32name="lib32"
	local _lib64name="lib"

	# External install
	if [ "$_EXTERNAL_INSTALL" = "true" ]; then
	  _lib32name="lib" && _lib64name="lib64"
	  if [ "$_EXTERNAL_NOVER" = "true" ]; then
	    _prefix="$_DEFAULT_EXTERNAL_PATH/$pkgname"
	  else
	    # $_realwineversion doesn't carry over into the fakeroot environment
	    if [ "$_use_staging" = "true" ]; then
	      cd "$srcdir/$_stgsrcdir"
	    else
	      cd "$srcdir/$_winesrcdir"
	    fi
	    _realwineversion=$(_describe_wine)
	    _prefix="$_DEFAULT_EXTERNAL_PATH/$pkgname-$_realwineversion"
	  fi
	fi

	if [ "$_NOLIB32" = "false" ]; then
	  # package wine 32-bit
	  # (according to the wine wiki, this reverse 32-bit/64-bit packaging order is important)
	  msg2 'Packaging Wine-32...'
	  cd "${srcdir}/${pkgname}"-32-build
	  make 	  prefix="${pkgdir}$_prefix" \
			  libdir="${pkgdir}$_prefix/$_lib32name" \
			  dlldir="${pkgdir}$_prefix/$_lib32name/wine" install
	fi

	if [ "$_NOLIB64" != "true" ]; then
	  # package wine 64-bit
	  msg2 'Packaging Wine-64...'
	  cd "${srcdir}/${pkgname}"-64-build
	  make 	  prefix="${pkgdir}$_prefix" \
			  libdir="${pkgdir}$_prefix/$_lib64name" \
			  dlldir="${pkgdir}$_prefix/$_lib64name/wine" install
	fi

	if [ "$_EXTERNAL_INSTALL" != "proton" ]; then
	  # freetype font smoothing for win32 applications
	  install -d "$pkgdir"/usr/share/fontconfig/conf.{avail,default}
	  install -m644 "$srcdir/30-win32-aliases.conf" "$pkgdir/usr/share/fontconfig/conf.avail/30-$pkgname-win32-aliases.conf"
	  ln -s "../conf.avail/30-$pkgname-win32-aliases.conf" "$pkgdir/usr/share/fontconfig/conf.default/30-$pkgname-win32-aliases.conf"
	fi

	# wine binfmt
	if [ "$_EXTERNAL_INSTALL" = "true" ]; then
	  mkdir -p "${pkgdir}/usr/lib/binfmt.d"
	  # change binfmt.conf to actual installed path
	  sed -e "s|/usr/bin/wine|$_prefix/bin/wine|g" < "${srcdir}/wine-binfmt.conf" > "${pkgdir}/usr/lib/binfmt.d/$pkgname.conf"
	  if [ "$_MIME_NOPE" = "true" ]; then
	    sed 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' "${pkgdir}$_prefix"/share/wine/wine.inf -i
	  fi
	  if [ "$_FOAS_NOPE" = "true" ]; then
	    sed 's|    LicenseInformation|    LicenseInformation,\\\n    FileOpenAssociations|g;$a \\n[FileOpenAssociations]\nHKCU,Software\\Wine\\FileOpenAssociations,"Enable",,"N"' "${pkgdir}$_prefix"/share/wine/wine.inf -i
	  fi
	elif [ "$_EXTERNAL_INSTALL" = "false" ]; then
	  install -Dm 644 "${srcdir}/wine-binfmt.conf" "${pkgdir}/usr/lib/binfmt.d/wine.conf"
	  # disable mime-types registering
	  if [ "$_MIME_NOPE" = "true" ]; then
	    sed 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' "${pkgdir}"/usr/share/wine/wine.inf -i
	  fi
	  if [ "$_FOAS_NOPE" = "true" ]; then
	    sed 's|    LicenseInformation|    LicenseInformation,\\\n    FileOpenAssociations|g;$a \\n[FileOpenAssociations]\nHKCU,Software\\Wine\\FileOpenAssociations,"Enable",,"N"' "${pkgdir}"/usr/share/wine/wine.inf -i
	  fi
	fi

	# wine-tkg path scripts - Might be useful for external builds when using weird env vars - Also workarounds wrong paths issues on non-Arch distros
	cp "$_where"/wine-tkg-scripts/wine-tkg "${pkgdir}$_prefix"/bin/wine-tkg
	cp "$_where"/wine-tkg-scripts/wine64-tkg "${pkgdir}$_prefix"/bin/wine64-tkg
	cp "$_where"/wine-tkg-scripts/wine-tkg-interactive "${pkgdir}$_prefix"/bin/wine-tkg-interactive

	# Fixes compatibility with installation scripts (like winetricks) that use
	# the wine64 binary, which is not present in WoW64 builds.
	if [ "$_NOLIB32" = "wow64" ]; then
	    ( cd "${pkgdir}$_prefix/bin" && ln -s wine wine64 )
	fi

	# strip
	if [ "$_EXTERNAL_INSTALL" != "proton" ]; then
	  if [ "$_protonify" = "true" ] && ( cd "${srcdir}"/"${_winesrcdir}" && ! git merge-base --is-ancestor 2e5e5ade82b5e3b1d70ebe6b1a824bdfdedfd04e HEAD ); then
	    if [ "$_pkg_strip" = "true" ]; then
	      msg2 "Fixing x86_64 PE files..."
	      find "${pkgdir}$_prefix"/"$_lib64name"/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' -or -iname '*.conf' ')' -printf '--strip-unneeded\0%p\0%p\0' | xargs -0 -r -P1 -n3 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
	      if [ "$_NOLIB32" != "true" ]; then
	        msg2 "Fixing i386 PE files..."
	        find "${pkgdir}$_prefix"/"$_lib32name"/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' -or -iname '*.conf' ')' -printf '--strip-unneeded\0%p\0%p\0' | xargs -0 -r -P1 -n3 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
		  fi
	      find "${pkgdir}$_prefix"/bin/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' ')' -printf '--strip-unneeded\0%p\0%p\0' | xargs -0 -r -P1 -n3 sh -c 'objcopy --file-alignment=4096 "$@" > /dev/null 2>&1; exit 0' cmd
	    else
	      msg2 "Fixing x86_64 PE files..."
	      find "${pkgdir}$_prefix"/"$_lib64name"/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' -or -iname '*.conf' ')' -printf '%p\0%p\0' | xargs -0 -r -P1 -n2 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
	      if [ "$_NOLIB32" != "true" ]; then
	        msg2 "Fixing i386 PE files..."
	        find "${pkgdir}$_prefix"/"$_lib32name"/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' -or -iname '*.conf' ')' -printf '%p\0%p\0' | xargs -0 -r -P1 -n2 objcopy --file-alignment=4096 --set-section-flags .text=contents,alloc,load,readonly,code
		  fi
	      find "${pkgdir}$_prefix"/bin/ -type f -not '(' -iname '*.pc' -or -iname '*.cmake' -or -iname '*.a' -or -iname '*.la' -or -iname '*.def' -or -iname '*.py' -or -iname '*.pyc' -or -iname '*.pl' ')' -printf '%p\0%p\0' | xargs -0 -r -P1 -n2 sh -c 'objcopy --file-alignment=4096 "$@" > /dev/null 2>&1; exit 0' cmd
	    fi
	  elif [ "$_pkg_strip" = "true" ]; then
	    for _f in $( find "${pkgdir}$_prefix" -type f '(' -iname '*.dll' -or -iname '*.so' -or -iname '*.sys' -or -iname '*.drv' -or -iname '*.exe' ')' ); do
	      strip --strip-unneeded "$_f" && msg2 "$_f stripped"
	    done
	  fi
	fi

	cp "$_where"/last_build_config.log "${pkgdir}$_prefix"/share/wine/wine-tkg-config.txt

	if [ "$_GENERATE_DEBIAN_PACKAGE" = "true" ] && [ "$_EXTERNAL_INSTALL" != "proton" ]; then
		_generate_debian_package "$_prefix"
	fi

	if [ "$_use_esync" = "true" ] || [ "$_staging_esync" = "true" ]; then
	  msg2 '##########################################################################################################################'
	  msg2 ''
	  msg2 'To enable esync, export WINEESYNC=1 and increase file descriptors limits in /etc/security/limits.conf to use ESYNC goodness ;)'
	  msg2 ''
	  msg2 'https://raw.githubusercontent.com/zfigura/wine/esync/README.esync'
	  msg2 ''
	  msg2 '##########################################################################################################################'
	  if [ "$_use_fsync" = "true" ]; then
	    msg2 '##########################################################################################################################'
	    msg2 ''
	    if [ "$_fsync_legacy" = "true" ]; then
	      msg2 'To enable fsync legacy, export WINEFSYNC=1 and use a linux54-tkg or newer. If no compatible kernel'
	      msg2 'is found and Esync is enabled, it will fallback to it. You can enable both to get a dynamic "failsafe" mechanism.'
	      msg2 ''
	      msg2 'https://steamcommunity.com/app/221410/discussions/0/3158631000006906163/'
	        if [ "$_fsync_futex2" = "true" ]; then
	          msg2 ''
	          msg2 'To enable fsync_futex2, additionally export WINEFSYNC_FUTEX2=1 and use a linux510-tkg or newer.'
	          msg2 ''
	          msg2 'https://github.com/ValveSoftware/Proton/issues/4568'
	        fi
	    else
	      msg2 'To enable fsync, export WINEFSYNC=1 and use a kernel 5.16+ (or at least linux513-tkg). If no compatible kernel'
	      msg2 'is found and Esync is enabled, it will fallback to it. You can enable both to get a dynamic "failsafe" mechanism.'
	      msg2 ''
	      msg2 'https://github.com/ValveSoftware/wine/pull/128'
	    fi
	    msg2 ''
	    msg2 '##########################################################################################################################'
	  fi
	fi

	if [ "$_use_fastsync" = "true" ]; then
	  msg2 '##########################################################################################################################'
	  msg2 ''
	  msg2 'To disable NTsync, export WINE_DISABLE_FAST_SYNC=1'
	  if [ "$_use_fsync" = "true" ]; then
	    msg2 'Any WINEESYNC and WINEFSYNC values will be ignored unless NTsync is disabled via an environment variable'
	  fi
	  msg2 ''
	  msg2 'https://github.com/Frogging-Family/wine-tkg-git/issues/936 - feedback topic for reporting test results'
	  msg2 "(please do not report issues related to builds or NTsync installation there - it's only for testing results)"
	  msg2 ''
	  msg2 '##########################################################################################################################'
	fi

	# External install
	if [ "$_EXTERNAL_INSTALL" = "true" ]; then
	  msg2 "### This wine will be installed to: $_prefix"
	  msg2 "### Remember to use $_prefix/bin/wine instead of just wine (same for winecfg etc.)"
	elif [ "$_EXTERNAL_INSTALL" = "proton" ]; then
	  touch "${pkgdir}"/../HL3_confirmed
	  msg2 'Use Gandalf to prevent packaging we do not need for proton'
	  YOU_SHALL_NOT_PASS
	fi
}

# Workaround
trap _exit_cleanup EXIT
