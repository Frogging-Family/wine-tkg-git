_exports_64() {
  if [ "$_NOCCACHE" != "true" ]; then
	if [ -e /usr/bin/ccache ]; then
		export CC="ccache gcc" && echo "CC = ${CC}" >>"$_LAST_BUILD_CONFIG"
		export CXX="ccache g++" && echo "CXX = ${CXX}" >>"$_LAST_BUILD_CONFIG"
	fi
	if [ -e /usr/bin/ccache ] && [ "$_NOMINGW" != "true" ]; then
		export CROSSCC="ccache x86_64-w64-mingw32-gcc" && echo "CROSSCC64 = ${CROSSCC}" >>"$_LAST_BUILD_CONFIG"
	fi
  fi
  # If /usr/lib32 doesn't exist (such as on Fedora), make sure we're using /usr/lib64 for 64-bit pkgconfig path
  if [ ! -d '/usr/lib32' ]; then
    export PKG_CONFIG_PATH='/usr/lib64/pkgconfig'
  fi
}

_configure_64() {
  msg2 'Configuring Wine-64...'
  cd  "${srcdir}"/"${pkgname}"-64-build
  if [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW3" =~ [yY] ]]; then
  chmod +x ../"${_winesrcdir}"/configure
    ../"${_winesrcdir}"/configure \
	    --prefix="$_prefix" \
		--enable-win64 \
		"${_configure_args64[@]}" \
		"${_configure_args[@]}"
  fi
  if [ "$_pkg_strip" != "true" ]; then
    msg2 "Disable strip"
    sed 's|STRIP = strip|STRIP =|g' "${srcdir}/${pkgname}"-64-build/Makefile -i
  fi
}

# Needed for _SINGLE_MAKE build
_tools_64() (
  msg2 'Building Wine-64 Tools...'
  shopt -s globstar
  for mkfile in tools/Makefile tools/**/Makefile; do
    "$@" -C "${mkfile%/Makefile}"
  done
)

_build_64() {
  msg2 'Building Wine-64...'
  cd  "${srcdir}"/"${pkgname}"-64-build
  if [ "$_SINGLE_MAKE" = 'true' ]; then
    exec "$@"
  elif [ "$_LOCAL_OPTIMIZED" = 'true' ]; then
    # make using all available threads
    if [ "$_log_errors_to_file" = "true" ]; then
      make -j$(nproc) 2> "$_where/debug.log"
    else
      #_buildtime64=$( time ( make -j$(nproc) 2>&1 ) 3>&1 1>&2 2>&3 ) - Bash 5.2 is frogged - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1018727
      make -j$(nproc)
    fi
  else
    # make using makepkg settings
    if [ "$_log_errors_to_file" = "true" ]; then
      make 2> "$_where/debug.log"
    else
      #_buildtime64=$( time ( make 2>&1 ) 3>&1 1>&2 2>&3 ) - Bash 5.2 is frogged - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1018727
      make
    fi
  fi
}
