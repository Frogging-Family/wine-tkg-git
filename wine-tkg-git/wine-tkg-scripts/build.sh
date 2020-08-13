#!/bin/bash

_prebuild_common() {
	cd "${srcdir}"

	echo "" >> "$_where"/last_build_config.log

	# Use custom compiler paths if defined
	if [ -n "${CUSTOM_MINGW_PATH}" ]; then
	  PATH="${PATH}:${CUSTOM_MINGW_PATH}/bin:${CUSTOM_MINGW_PATH}/lib:${CUSTOM_MINGW_PATH}/include"
	  echo -e "CUSTOM_MINGW_PATH = ${CUSTOM_MINGW_PATH##*/}" >> "$_where"/last_build_config.log
	fi
	if [ -n "${CUSTOM_GCC_PATH}" ]; then
	  PATH="${CUSTOM_GCC_PATH}/bin:${CUSTOM_GCC_PATH}/lib:${CUSTOM_GCC_PATH}/include:${PATH}"
	  echo -e "CUSTOM_GCC_PATH = ${CUSTOM_GCC_PATH##*/}" >> "$_where"/last_build_config.log
	fi

	echo "" >> "$_where"/last_build_config.log

	# compiler flags
	if [ "$_LOCAL_OPTIMIZED" = "true" ]; then
	  export CFLAGS="${_GCC_FLAGS}"
	  export CXXFLAGS="${_GCC_FLAGS}"
	  export LDFLAGS="${_LD_FLAGS}"
	  export CROSSCFLAGS="${_CROSS_FLAGS}"
	  export CROSSLDFLAGS="${_CROSS_LD_FLAGS}"
	  echo "With predefined optimizations:" >> "$_where"/last_build_config.log
	else
	  export CROSSCFLAGS="$(echo "$CFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/-fno-plt//")"
	  export CROSSLDFLAGS="$(echo "$CFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/,-z,now//" -e "s/-fno-plt//")"
	  echo "Using /etc/makepkg.conf settings for compiler optimization flags" >> "$_where"/last_build_config.log
	fi

	# workaround for FS#55128
	# https://bugs.archlinux.org/task/55128
	# https://bugs.winehq.org/show_bug.cgi?id=43530
	export CFLAGS="$(echo "$CFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/-fno-plt//")"
	export LDFLAGS="$(echo "$LDFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/,-z,now//" -e "s/-fno-plt//")"
	export CROSSCFLAGS="$(echo "$CROSSCFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/-fno-plt//")"
	export CROSSLDFLAGS="$(echo "$CROSSLDFLAGS" | sed -e "s/-fstack-protector-strong//" -e "s/,-z,now//" -e "s/-fno-plt//")"
	echo "CFLAGS = ${CFLAGS}" >> "$_where"/last_build_config.log
	echo "LDFLAGS = ${LDFLAGS}" >> "$_where"/last_build_config.log
	echo "CROSSCFLAGS = ${CROSSCFLAGS}" >> "$_where"/last_build_config.log
	echo "CROSSLDFLAGS = ${CROSSLDFLAGS}" >> "$_where"/last_build_config.log

	# Disable tests by default, enable back with _enable_tests="true"
	if [ "$_ENABLE_TESTS" != "true" ]; then
	  _configure_args+=(--disable-tests)
	fi
}

_build() {
	if [ "$_NOLIB64" != "true" ]; then
	  # build wine 64-bit
	  # (according to the wine wiki, this 64-bit/32-bit building order is mandatory)
	  if [[ ! ${_makepkg_options[*]} =~ "ccache" ]] && [ -e /usr/bin/ccache ]; then
	    export CC="ccache gcc" && echo "CC = ${CC}" >> "$_where"/last_build_config.log
	    export CXX="ccache g++" && echo "CXX = ${CXX}" >> "$_where"/last_build_config.log
	  fi
	  if [ -e /usr/bin/ccache ] && [ "$_NOMINGW" != "true" ]; then
	    export CROSSCC="ccache x86_64-w64-mingw32-gcc" && echo "CROSSCC64 = ${CROSSCC}" >> "$_where"/last_build_config.log
	  fi
	  # If /usr/lib32 doesn't exist (such as on Fedora), make sure we're using /usr/lib64 for 64-bit pkgconfig path
	  if [ ! -d '/usr/lib32' ]; then
	    export PKG_CONFIG_PATH='/usr/lib64/pkgconfig'
	  fi
	  msg2 'Building Wine-64...'
	  cd  "${srcdir}"/"${pkgname}"-64-build
	  if [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW3" =~ [yY] ]]; then
	    ../${_winesrcdir}/configure \
		    --prefix="$_prefix" \
			--enable-win64 \
			"${_configure_args64[@]}" \
			"${_configure_args[@]}"
	  fi
	  if [ "$_LOCAL_OPTIMIZED" = 'true' ]; then
	    # make using all available threads
	    _buildtime64=$( time ( schedtool -B -n 1 -e ionice -n 1 make -j$(nproc) 2>&1 ) 3>&1 1>&2 2>&3 ) || _buildtime64=$( time ( make -j$(nproc) 2>&1 ) 3>&1 1>&2 2>&3 )
	  else
	    # make using makepkg settings
	    _buildtime64=$( time ( schedtool -B -n 1 -e ionice -n 1 make 2>&1 ) 3>&1 1>&2 2>&3 ) || _buildtime64=$( time ( make 2>&1 ) 3>&1 1>&2 2>&3 )
	  fi
	fi

	if [ "$_NOLIB32" != "true" ]; then
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
	  if [[ ! ${_makepkg_options[*]} =~ "ccache" ]] && [ -e /usr/bin/ccache ]; then
	    export CC="ccache gcc"
	    export CXX="ccache g++"
	  fi
	  if [ -e /usr/bin/ccache ] && [ "$_NOMINGW" != "true" ]; then
	    export CROSSCC="ccache i686-w64-mingw32-gcc" && echo "CROSSCC32 = ${CROSSCC}" >> "$_where"/last_build_config.log
	  fi
	  # build wine 32-bit
	  if [ -d '/usr/lib32/pkgconfig' ]; then # Typical Arch path
	    export PKG_CONFIG_PATH='/usr/lib32/pkgconfig'
	  elif [ -d '/usr/lib/i386-linux-gnu/pkgconfig' ]; then # Ubuntu 18.04/19.04 path
	    export PKG_CONFIG_PATH='/usr/lib/i386-linux-gnu/pkgconfig'
	  else
	    export PKG_CONFIG_PATH='/usr/lib/pkgconfig' # Pretty common path, possibly helpful for OpenSuse & Fedora
	  fi
	  msg2 'Building Wine-32...'
	  cd "${srcdir}/${pkgname}"-32-build
	  if [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW3" =~ [yY] ]]; then
		 if [ "$_NOLIB64" = "true" ]; then
	       ../${_winesrcdir}/configure \
		      --prefix="$_prefix" \
		      "${_configure_args32[@]}" \
		      "${_configure_args[@]}"
		  else
	        ../${_winesrcdir}/configure \
		      --prefix="$_prefix" \
		      "${_configure_args32[@]}" \
		      "${_configure_args[@]}" \
		      --with-wine64="${srcdir}/${pkgname}"-64-build
		 fi
	  fi
	  if [ "$_LOCAL_OPTIMIZED" = 'true' ]; then
	    # make using all available threads
	    _buildtime32=$( time ( schedtool -B -n 1 -e ionice -n 1 make -j$(nproc) 2>&1 ) 3>&1 1>&2 2>&3 ) || _buildtime32=$( time ( make -j$(nproc) 2>&1 ) 3>&1 1>&2 2>&3 )
	  else
	    # make using makepkg settings
	    _buildtime32=$( time ( schedtool -B -n 1 -e ionice -n 1 make 2>&1 ) 3>&1 1>&2 2>&3 ) || _buildtime32=$( time ( make 2>&1 ) 3>&1 1>&2 2>&3 )
	  fi
	fi
}

_generate_debian_package() {
	_prefix=$1

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
	local _lib32name="lib32"
	local _lib64name="lib"

	# External install
	if [ "$_EXTERNAL_INSTALL" = "true" ]; then
	  _lib32name="lib" && _lib64name="lib64"
	  if [ "$_EXTERNAL_INSTALL_TYPE" != "proton" ]; then
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
	fi

	if [ "$_NOLIB32" != "true" ]; then
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

	# strip
	if [ "$_pkg_strip" = "true" ]; then
	  for _f in "$_prefix"/{bin,lib,lib32,lib64}/{wine/*,*}; do
	    if [[ "$_f" = *.so ]] || [[ "$_f" = *.dll ]]; then
	      strip --strip-unneeded "$_f"
	    fi
	  done
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

	if [ "$_GENERATE_DEBIAN_PACKAGE" = "true" ] && [ "$_EXTERNAL_INSTALL_TYPE" != "proton" ]; then
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
	    msg2 'To enable fsync, export WINEFSYNC=1 and use a Fsync patched kernel (such as linux52-tkg or newer). If no compatible kernel'
	    msg2 'is found and Esync is enabled, it will fallback to it. You can enable both to get a dynamic "failsafe" mechanism.'
	    msg2 ''
	    msg2 'https://steamcommunity.com/app/221410/discussions/0/3158631000006906163/'
	    msg2 ''
	    msg2 '##########################################################################################################################'
	  fi
	fi

	# External install
	if [ "$_EXTERNAL_INSTALL" = "true" ] && [ "$_EXTERNAL_INSTALL_TYPE" != "proton" ]; then
	  msg2 "### This wine will be installed to: $_prefix"
	  msg2 "### Remember to use $_prefix/bin/wine instead of just wine (same for winecfg etc.)"
	elif [ "$_EXTERNAL_INSTALL" = "true" ] && [ "$_EXTERNAL_INSTALL_TYPE" = "proton" ]; then
	  touch "${pkgdir}"/../HL3_confirmed
	fi
}

_package_makepkg() {
	local _prefix=/usr
	local _lib32name="lib32"
	local _lib64name="lib"

	# External install
	if [ "$_EXTERNAL_INSTALL" = "true" ]; then
	  _lib32name="lib" && _lib64name="lib64"
	  if [ "$_EXTERNAL_INSTALL_TYPE" != "proton" ]; then
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
	  elif [ "$_EXTERNAL_INSTALL_TYPE" = "proton" ]; then
	    _prefix=""
	  fi
	fi

	if [ "$_NOLIB32" != "true" ]; then
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

	if [ "$_EXTERNAL_INSTALL" = "true" ] && [ "$_EXTERNAL_INSTALL_TYPE" != "proton" ] || [ "$_EXTERNAL_INSTALL" != "true" ]; then
	  # freetype font smoothing for win32 applications
	  install -d "$pkgdir"/etc/fonts/conf.{avail,d}
	  install -m644 "${srcdir}/30-win32-aliases.conf" "${pkgdir}/etc/fonts/conf.avail/30-$pkgname-win32-aliases.conf"
	  ln -s "../conf.avail/30-$pkgname-win32-aliases.conf" "${pkgdir}/etc/fonts/conf.d/30-$pkgname-win32-aliases.conf"
	fi

	# wine binfmt
	if [ "$_EXTERNAL_INSTALL" = "true" ] && [ "$_EXTERNAL_INSTALL_TYPE" != "proton" ]; then
	  mkdir -p "${pkgdir}/usr/lib/binfmt.d"
	  # change binfmt.conf to actual installed path
	  sed -e "s|/usr/bin/wine|$_prefix/bin/wine|g" < "${srcdir}/wine-binfmt.conf" > "${pkgdir}/usr/lib/binfmt.d/$pkgname.conf"
	  if [ "$_MIME_NOPE" = "true" ]; then
	    sed 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' "${pkgdir}$_prefix"/share/wine/wine.inf -i
	  fi
	  if [ "$_FOAS_NOPE" = "true" ]; then
	    sed 's|    LicenseInformation|    LicenseInformation,\\\n    FileOpenAssociations|g;$a \\n[FileOpenAssociations]\nHKCU,Software\\Wine\\FileOpenAssociations,"Enable",,"N"' "${pkgdir}$_prefix"/share/wine/wine.inf -i
	  fi
	elif [ "$_EXTERNAL_INSTALL" != "true" ]; then
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

	cp "$_where"/last_build_config.log "${pkgdir}$_prefix"/share/wine/wine-tkg-config.txt

	if [ "$_GENERATE_DEBIAN_PACKAGE" = "true" ] && [ "$_EXTERNAL_INSTALL_TYPE" != "proton" ]; then
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
	    msg2 'To enable fsync, export WINEFSYNC=1 and use a Fsync patched kernel (such as linux52-tkg or newer). If no compatible kernel'
	    msg2 'is found and Esync is enabled, it will fallback to it. You can enable both to get a dynamic "failsafe" mechanism.'
	    msg2 ''
	    msg2 'https://steamcommunity.com/app/221410/discussions/0/3158631000006906163/'
	    msg2 ''
	    msg2 '##########################################################################################################################'
	  fi
	fi

	# External install
	if [ "$_EXTERNAL_INSTALL" = "true" ] && [ "$_EXTERNAL_INSTALL_TYPE" != "proton" ]; then
	  msg2 "### This wine will be installed to: $_prefix"
	  msg2 "### Remember to use $_prefix/bin/wine instead of just wine (same for winecfg etc.)"
	elif [ "$_EXTERNAL_INSTALL" = "true" ] && [ "$_EXTERNAL_INSTALL_TYPE" = "proton" ]; then
	  touch "${pkgdir}"/../HL3_confirmed
	  msg2 'Use Gandalf to prevent packaging we do not need for proton'
	  YOU_SHALL_NOT_PASS
	fi
}

# Workaround
trap _exit_cleanup EXIT
