#!/bin/bash

_exports_32() {
  if [ "$_NOCCACHE" != "true" ]; then
    if [ -e /usr/bin/ccache ]; then
      export CC="ccache gcc"
      export CXX="ccache g++"
    fi
    if [ -e /usr/bin/ccache ] && [ "$_NOMINGW" != "true" ]; then
      export CROSSCC="ccache i686-w64-mingw32-gcc" && echo "CROSSCC32 = ${CROSSCC}" >>"$_LAST_BUILD_CONFIG"
      export i386_CC="${CROSSCC}"
    fi
  fi
  # build wine 32-bit
  if [ -d '/usr/lib32/pkgconfig' ]; then # Typical Arch path
    export PKG_CONFIG_PATH='/usr/lib32/pkgconfig'
    # glib/gstreamer detection workaround for proton 8.0 trees
    if [[ "$_plain_version" = *_8.0 ]] || [[ "$_plain_version" = *_9.0 ]]; then
      CFLAGS+=" -I/usr/lib32/glib-2.0/include -I/usr/include/glib-2.0 -I/usr/include/gstreamer-1.0 -I/usr/lib32/gstreamer-1.0/include"
      CROSSCFLAGS+=" -I/usr/lib32/glib-2.0/include -I/usr/include/glib-2.0 -I/usr/include/gstreamer-1.0 -I/usr/lib32/gstreamer-1.0/include"
    fi
  elif [ -d '/usr/lib/i386-linux-gnu/pkgconfig' ]; then # Ubuntu 18.04/19.04 path
    export PKG_CONFIG_PATH='/usr/lib/i386-linux-gnu/pkgconfig'
    if [[ "$_plain_version" = *_8.0 ]] || [[ "$_plain_version" = *_9.0 ]]; then
      CFLAGS+=" -I/usr/lib/i386-linux-gnu/glib-2.0/include -I/usr/include/glib-2.0 -I/usr/include/gstreamer-1.0 -I/usr/lib/i386-linux-gnu/gstreamer-1.0/include"
      CROSSCFLAGS+=" -I/usr/lib/i386-linux-gnu/glib-2.0/include -I/usr/include/glib-2.0 -I/usr/include/gstreamer-1.0 -I/usr/lib/i386-linux-gnu/gstreamer-1.0/include"
    fi
  else
    export PKG_CONFIG_PATH='/usr/lib/pkgconfig' # Pretty common path, possibly helpful for OpenSuse & Fedora
    # Workaround for Fedora freetype2 libs not being detected now that it's been moved to a subdir
    CFLAGS+=" -I/usr/include/freetype2"
    CROSSCFLAGS+=" -I/usr/include/freetype2"
    if [[ "$_plain_version" = *_8.0 ]] || [[ "$_plain_version" = *_9.0 ]]; then
      CFLAGS+=" -I/usr/lib/glib-2.0/include -I/usr/include/glib-2.0 -I/usr/include/gstreamer-1.0 -I/usr/lib/gstreamer-1.0/include"
      CROSSCFLAGS+=" -I/usr/lib/glib-2.0/include -I/usr/include/glib-2.0 -I/usr/include/gstreamer-1.0 -I/usr/lib/gstreamer-1.0/include"
    fi
  fi
}

_configure_32() {
  msg2 'Configuring Wine-32...'
  cd "${srcdir}/${pkgname}"-32-build
  if [ "$_NUKR" != "debug" ] || [[ "$_DEBUGANSW3" =~ [yY] ]]; then
    if [ "$_NOLIB64" = "true" ]; then
      ../"${_winesrcdir}"/configure \
        --prefix="$_prefix" \
        "${_configure_args32[@]}" \
        "${_configure_args[@]}"
    else
      ../"${_winesrcdir}"/configure \
        --prefix="$_prefix" \
        "${_configure_args32[@]}" \
        "${_configure_args[@]}" \
        --with-wine64="${srcdir}/${pkgname}"-64-build
    fi
  fi
  if [ "$_pkg_strip" != "true" ]; then
    msg2 "Disable strip"
    sed 's|STRIP = strip|STRIP =|g' "${srcdir}/${pkgname}"-32-build/Makefile -i
  fi
}

_build_32() {
  msg2 'Building Wine-32...'
  cd "${srcdir}/${pkgname}"-32-build
  if [ "$_SINGLE_MAKE" = 'true' ]; then
    MAKEFLAGS="${MFLAGS#-j* }"
    exec "$@"
  elif [ "$_LOCAL_OPTIMIZED" = 'true' ]; then
    # make using all available threads
    if [ "$_log_errors_to_file" = "true" ]; then
      make -j$(nproc) 2>"$_where/debug.log"
    else
      #_buildtime32=$( time ( make -j$(nproc) 2>&1 ) 3>&1 1>&2 2>&3 ) - Bash 5.2 is frogged - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1018727
      make -j$(nproc)
    fi
  else
    # make using makepkg settings
    if [ "$_log_errors_to_file" = "true" ]; then
      make 2>"$_where/debug.log"
    else
      #_buildtime32=$( time ( make 2>&1 ) 3>&1 1>&2 2>&3 ) - Bash 5.2 is frogged - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1018727
      make
    fi
  fi
}
