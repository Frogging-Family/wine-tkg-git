#!/bin/bash

  # mpeg2dec and x264 are kinda widely used but unavailable as lib32 in Arch repos - enable optionally
  _use_lib32_mpeg2dec_and_x264="false"

  _nowhere="$(dirname "$PWD")"
  #_nowhere="$PWD"
  source "$_nowhere/proton_tkg_token" || source "$_nowhere/src/proton_tkg_token"

  # Disable lib32 stuff when _NOLIB32 is enabled
  if [ "$_NOLIB32" = "true" ]; then
    _lib32_gstreamer="false"
    _use_lib32_mpeg2dec_and_x264="false"
  fi

  cd "$_nowhere"/external-resources

  git clone https://github.com/GStreamer/gstreamer.git || true # It'll complain the path already exists on subsequent builds
  cd gstreamer
  git reset --hard HEAD
  git clean -xdf
  git pull origin main
  #git checkout f0b045a69bb0b36515b84e3b64df9dc30c8f1e1a
  cd ..

  git clone https://github.com/FFmpeg/FFmpeg.git || true # It'll complain the path already exists on subsequent builds
  cd FFmpeg
  git reset --hard HEAD
  git clean -xdf
  git pull origin master
  #git checkout a77521c
  cd ..

  if [ "$_build_faudio" = "true" ]; then
    git clone https://github.com/FNA-XNA/FAudio.git || true # It'll complain the path already exists on subsequent builds
    cd FAudio
    git reset --hard HEAD
    git clean -xdf
    git checkout d6b3e87720691bddd421673e4a9ea47a690b8fab # Last commit before gstreamer support removal - which we currently still need for wma playback
    cd ..
    rm -rf FAudio32 && cp -R FAudio FAudio32
    rm -rf "$_nowhere"/Proton/build/faudio*
  fi

  rm -rf "$_nowhere"/Proton/{gstreamer,FFmpeg,FAudio}
  ln -s "$_nowhere"/external-resources/{gstreamer,FFmpeg,FAudio} "$_nowhere"/Proton/

  rm -rf "$_nowhere"/Proton/build/gst*

  unset CFLAGS
  unset CPPFLAGS
  unset CXXFLAGS
  unset LDFLAGS

  ##### 64

  # If /usr/lib32 doesn't exist (such as on Fedora), make sure we're using /usr/lib64 for 64-bit pkgconfig path
  if [ ! -d '/usr/lib32' ]; then
    export PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib64/pkgconfig:/usr/lib64/pkgconfig"
  else
    export PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib64/pkgconfig"
  fi

  if [ "$_build_ffmpeg" = "true" ]; then
	mkdir -p "$_nowhere"/Proton/build/FFmpeg64 && cd "$_nowhere"/Proton/build/FFmpeg64

	"$_nowhere"/Proton/FFmpeg/configure \
		--prefix="$_nowhere/gst" \
		--libdir="$_nowhere/gst/lib64" \
		--enable-shared \
		--disable-static \
		--disable-everything \
		--disable-programs \
		--disable-doc \
		--enable-decoder=mpeg4 \
		--enable-decoder=msmpeg4v1 \
		--enable-decoder=msmpeg4v2 \
		--enable-decoder=msmpeg4v3 \
		--enable-decoder=vc1 \
		--enable-decoder=wmav1 \
		--enable-decoder=wmav2 \
		--enable-decoder=wmapro \
		--enable-decoder=wmalossless \
		--enable-decoder=xma1 \
		--enable-decoder=xma2 \
		--enable-decoder=wmv3image \
		--enable-decoder=wmv3 \
		--enable-decoder=wmv2 \
		--enable-decoder=wmv1 \
		--enable-decoder=h264 \
		--enable-decoder=aac \
		--enable-demuxer=xwma

	make && make install
  fi

  cd "$_nowhere"/Proton/gstreamer
  mkdir -p "$_nowhere"/Proton/build/gst64

  meson_options=(
    -D devtools=disabled
    -D tests=disabled
    -D doc=disabled
    -D examples=disabled
    -D python=disabled
    -D ges=disabled
    -D gpl=enabled
    -D gst-examples=disabled
    -D libnice=disabled
    -D vaapi=disabled
    -D introspection=disabled
    -D orc-source=auto
    -D gstreamer:dbghelp=disabled
    -D gstreamer:gobject-cast-checks=disabled
    -D gstreamer:ptp-helper-permissions=capabilities
    -D gstreamer:introspection=disabled
    -D gstreamer:gst_parse=false
    -D gstreamer:benchmarks=disabled
    -D gstreamer:tools=disabled
    -D gstreamer:bash-completion=disabled
    -D gstreamer:examples=disabled
    -D gstreamer:tests=disabled
    -D gstreamer:glib-asserts=disabled
    -D gstreamer:glib-checks=disabled
    -D gstreamer:nls=disabled
    -D gst-plugins-base:gobject-cast-checks=disabled
    -D gst-plugins-base:tremor=disabled
    -D gst-plugins-base:theora=disabled
	-D gst-plugins-base:alsa=disabled
	-D gst-plugins-base:audiomixer=disabled
	-D gst-plugins-base:audiorate=disabled
	-D gst-plugins-base:audiotestsrc=disabled
	-D gst-plugins-base:cdparanoia=disabled
	-D gst-plugins-base:compositor=disabled
	-D gst-plugins-base:encoding=disabled
	-D gst-plugins-base:gio=disabled
	-D gst-plugins-base:gl=disabled
	-D gst-plugins-base:libvisual=disabled
	-D gst-plugins-base:overlaycomposition=disabled
	-D gst-plugins-base:pango=disabled
	-D gst-plugins-base:rawparse=disabled
	-D gst-plugins-base:subparse=disabled
	-D gst-plugins-base:tcp=disabled
	-D gst-plugins-base:videorate=disabled
	-D gst-plugins-base:videotestsrc=disabled
	-D gst-plugins-base:volume=disabled
	-D gst-plugins-base:x11=disabled
	-D gst-plugins-base:xshm=disabled
	-D gst-plugins-base:xvideo=disabled
	-D gst-plugins-base:tools=disabled
	-D gst-plugins-base:examples=disabled
	-D gst-plugins-base:tests=disabled
	-D gst-plugins-base:introspection=disabled
	-D gst-plugins-base:gobject-cast-checks=disabled
	-D gst-plugins-base:glib-asserts=disabled
	-D gst-plugins-base:glib-checks=disabled
	-D gst-plugins-base:nls=disabled
    -D gst-plugins-good:gobject-cast-checks=disabled
    -D gst-plugins-good:rpicamsrc=disabled
	-D gst-plugins-good:aalib=disabled
	-D gst-plugins-good:alpha=disabled
	-D gst-plugins-good:apetag=disabled
	-D gst-plugins-good:audiofx=disabled
	-D gst-plugins-good:auparse=disabled
	-D gst-plugins-good:cairo=disabled
	-D gst-plugins-good:cutter=disabled
	-D gst-plugins-good:dtmf=disabled
	-D gst-plugins-good:effectv=disabled
	-D gst-plugins-good:equalizer=disabled
	-D gst-plugins-good:gdk-pixbuf=disabled
	-D gst-plugins-good:gtk3=disabled
	-D gst-plugins-good:goom=disabled
	-D gst-plugins-good:goom2k1=disabled
	-D gst-plugins-good:icydemux=disabled
	-D gst-plugins-good:imagefreeze=disabled
	-D gst-plugins-good:interleave=disabled
	-D gst-plugins-good:jack=disabled
	-D gst-plugins-good:law=disabled
	-D gst-plugins-good:level=disabled
	-D gst-plugins-good:libcaca=disabled
	-D gst-plugins-good:monoscope=disabled
	-D gst-plugins-good:multifile=disabled
	-D gst-plugins-good:multipart=disabled
	-D gst-plugins-good:oss=disabled
	-D gst-plugins-good:oss4=disabled
	-D gst-plugins-good:png=disabled
	-D gst-plugins-good:pulse=disabled
	-D gst-plugins-good:qt5=disabled
	-D gst-plugins-good:replaygain=disabled
	-D gst-plugins-good:rtp=disabled
	-D gst-plugins-good:rtpmanager=disabled
	-D gst-plugins-good:rtsp=disabled
	-D gst-plugins-good:shapewipe=disabled
	-D gst-plugins-good:shout2=disabled
	-D gst-plugins-good:smpte=disabled
	-D gst-plugins-good:soup=disabled
	-D gst-plugins-good:spectrum=disabled
	-D gst-plugins-good:taglib=disabled
	-D gst-plugins-good:udp=disabled
	-D gst-plugins-good:v4l2=disabled
	-D gst-plugins-good:videocrop=disabled
	-D gst-plugins-good:videomixer=disabled
	-D gst-plugins-good:wavenc=disabled
	-D gst-plugins-good:ximagesrc=disabled
	-D gst-plugins-good:y4m=disabled
    -D gst-plugins-bad:directfb=disabled
    -D gst-plugins-bad:flite=disabled
    -D gst-plugins-bad:gobject-cast-checks=disabled
    -D gst-plugins-bad:gs=disabled
    -D gst-plugins-bad:iqa=disabled
    -D gst-plugins-bad:isac=disabled
    -D gst-plugins-bad:magicleap=disabled
    -D gst-plugins-bad:onnx=disabled
    -D gst-plugins-bad:openh264=disabled
    -D gst-plugins-bad:openni2=disabled
    -D gst-plugins-bad:opensles=disabled
    -D gst-plugins-bad:tinyalsa=disabled
    -D gst-plugins-bad:voaacenc=disabled
    -D gst-plugins-bad:voamrwbenc=disabled
    -D gst-plugins-bad:wasapi2=disabled
    -D gst-plugins-bad:wasapi=disabled
	-D gst-plugins-bad:fbdev=disabled
	-D gst-plugins-bad:decklink=disabled
	-D gst-plugins-bad:dts=disabled
	-D gst-plugins-bad:faac=disabled
	-D gst-plugins-bad:faad=disabled
	-D gst-plugins-bad:mpeg2enc=disabled
	-D gst-plugins-bad:mplex=disabled
	-D gst-plugins-bad:neon=disabled
	-D gst-plugins-bad:rtmp=disabled
	-D gst-plugins-bad:flite=disabled
	-D gst-plugins-bad:vulkan=disabled
	-D gst-plugins-bad:sbc=disabled
	-D gst-plugins-bad:opencv=disabled
	-D gst-plugins-bad:voamrwbenc=disabled
	-D gst-plugins-bad:x265=disabled
	-D gst-plugins-bad:openexr=disabled
    -D gst-plugins-ugly:gobject-cast-checks=disabled
    -D gst-rtsp-server:gobject-cast-checks=disabled
    -D gst-editing-services:validate=disabled
  )

  meson "$_nowhere"/Proton/build/gst64 --prefix="$_nowhere/gst" --libdir="lib64" --buildtype=release -Dpkg_config_path="$_nowhere/gst/lib64/pkgconfig" "${meson_options[@]}"
  meson compile -C "$_nowhere"/Proton/build/gst64
  meson install -C "$_nowhere"/Proton/build/gst64

  # FAudio
  if [ "$_build_faudio" = "true" ]; then
    mkdir -p "$_nowhere"/Proton/build/faudio64/build
    cp -a "$_nowhere"/Proton/FAudio/* "$_nowhere"/Proton/build/faudio64 && cd "$_nowhere"/Proton/build/faudio64/build
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -Dpkg_config_path="$_nowhere"/gst/lib64/pkgconfig \
        -DCMAKE_INSTALL_PREFIX="$_nowhere"/gst \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_INSTALL_INCLUDEDIR=include/FAudio \
        -DGSTREAMER=ON
    make && make install
  fi

  strip --strip-unneeded "$_nowhere"/gst/lib64/*.so

  ##### 32
  if [ "$_lib32_gstreamer" = "true" ]; then
    (
    if [ -d '/usr/lib32/pkgconfig' ]; then # Typical Arch path
        export PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib/pkgconfig:/usr/lib32/pkgconfig"
    elif [ -d '/usr/lib/i386-linux-gnu/pkgconfig' ]; then # Ubuntu 18.04/19.04 path
        export PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib/pkgconfig:/usr/lib/i386-linux-gnu/pkgconfig"
    else
        export PKG_CONFIG_PATH="$_proton_tkg_path/gst/lib/pkgconfig:/usr/lib/pkgconfig" # Pretty common path, possibly helpful for OpenSuse & Fedora
    fi
    export CC="gcc -m32"
    export CXX="g++ -m32"

    if [ "$_build_ffmpeg" = "true" ]; then
		mkdir -p "$_nowhere"/Proton/build/FFmpeg32 && cd "$_nowhere"/Proton/build/FFmpeg32

		"$_nowhere"/Proton/FFmpeg/configure \
			--cc="$CC" \
			--prefix="$_nowhere/gst" \
			--libdir="$_nowhere/gst/lib" \
			--enable-shared \
			--disable-static \
			--disable-everything \
			--disable-programs \
			--disable-doc \
			--enable-decoder=mpeg4 \
			--enable-decoder=msmpeg4v1 \
			--enable-decoder=msmpeg4v2 \
			--enable-decoder=msmpeg4v3 \
			--enable-decoder=vc1 \
			--enable-decoder=wmav1 \
			--enable-decoder=wmav2 \
			--enable-decoder=wmapro \
			--enable-decoder=wmalossless \
			--enable-decoder=xma1 \
			--enable-decoder=xma2 \
			--enable-decoder=wmv3image \
			--enable-decoder=wmv3 \
			--enable-decoder=wmv2 \
			--enable-decoder=wmv1 \
			--enable-decoder=h264 \
			--enable-decoder=aac \
			--enable-demuxer=xwma

		make && make install
    fi

    cd "$_nowhere"/Proton/gstreamer
    mkdir -p "$_nowhere"/Proton/build/gst32

    # Not sure if amrnb and amrwbdec are used much in games
    meson32_options=(
    -D devtools=disabled
    -D tests=disabled
    -D doc=disabled
    -D examples=disabled
    -D python=disabled
    -D ges=disabled
    -D gpl=enabled
    -D gst-examples=disabled
    -D libnice=disabled
    -D vaapi=disabled
    -D introspection=disabled
    -D orc-source=auto
    -D gstreamer:dbghelp=disabled
    -D gstreamer:gobject-cast-checks=disabled
    -D gstreamer:ptp-helper-permissions=capabilities
    -D gstreamer:introspection=disabled
    -D gstreamer:gst_parse=false
    -D gstreamer:benchmarks=disabled
    -D gstreamer:tools=disabled
    -D gstreamer:bash-completion=disabled
    -D gstreamer:examples=disabled
    -D gstreamer:tests=disabled
    -D gstreamer:glib-asserts=disabled
    -D gstreamer:glib-checks=disabled
    -D gstreamer:nls=disabled
    -D gst-plugins-base:gobject-cast-checks=disabled
    -D gst-plugins-base:tremor=disabled
    -D gst-plugins-base:theora=disabled
	-D gst-plugins-base:alsa=disabled
	-D gst-plugins-base:audiomixer=disabled
	-D gst-plugins-base:audiorate=disabled
	-D gst-plugins-base:audiotestsrc=disabled
	-D gst-plugins-base:cdparanoia=disabled
	-D gst-plugins-base:compositor=disabled
	-D gst-plugins-base:encoding=disabled
	-D gst-plugins-base:gio=disabled
	-D gst-plugins-base:gl=disabled
	-D gst-plugins-base:libvisual=disabled
	-D gst-plugins-base:overlaycomposition=disabled
	-D gst-plugins-base:pango=disabled
	-D gst-plugins-base:rawparse=disabled
	-D gst-plugins-base:subparse=disabled
	-D gst-plugins-base:tcp=disabled
	-D gst-plugins-base:videorate=disabled
	-D gst-plugins-base:videotestsrc=disabled
	-D gst-plugins-base:volume=disabled
	-D gst-plugins-base:x11=disabled
	-D gst-plugins-base:xshm=disabled
	-D gst-plugins-base:xvideo=disabled
	-D gst-plugins-base:tools=disabled
	-D gst-plugins-base:examples=disabled
	-D gst-plugins-base:tests=disabled
	-D gst-plugins-base:introspection=disabled
	-D gst-plugins-base:gobject-cast-checks=disabled
	-D gst-plugins-base:glib-asserts=disabled
	-D gst-plugins-base:glib-checks=disabled
	-D gst-plugins-base:nls=disabled
    -D gst-plugins-good:gobject-cast-checks=disabled
    -D gst-plugins-good:rpicamsrc=disabled
	-D gst-plugins-good:aalib=disabled
	-D gst-plugins-good:alpha=disabled
	-D gst-plugins-good:apetag=disabled
	-D gst-plugins-good:audiofx=disabled
	-D gst-plugins-good:auparse=disabled
	-D gst-plugins-good:cairo=disabled
	-D gst-plugins-good:cutter=disabled
	-D gst-plugins-good:dtmf=disabled
	-D gst-plugins-good:effectv=disabled
	-D gst-plugins-good:equalizer=disabled
	-D gst-plugins-good:gdk-pixbuf=disabled
	-D gst-plugins-good:gtk3=disabled
	-D gst-plugins-good:goom=disabled
	-D gst-plugins-good:goom2k1=disabled
	-D gst-plugins-good:icydemux=disabled
	-D gst-plugins-good:imagefreeze=disabled
	-D gst-plugins-good:interleave=disabled
	-D gst-plugins-good:jack=disabled
	-D gst-plugins-good:lame=disabled
	-D gst-plugins-good:law=disabled
	-D gst-plugins-good:level=disabled
	-D gst-plugins-good:libcaca=disabled
	-D gst-plugins-good:monoscope=disabled
	-D gst-plugins-good:multifile=disabled
	-D gst-plugins-good:multipart=disabled
	-D gst-plugins-good:oss=disabled
	-D gst-plugins-good:oss4=disabled
	-D gst-plugins-good:png=disabled
	-D gst-plugins-good:pulse=disabled
	-D gst-plugins-good:qt5=disabled
	-D gst-plugins-good:replaygain=disabled
	-D gst-plugins-good:rtp=disabled
	-D gst-plugins-good:rtpmanager=disabled
	-D gst-plugins-good:rtsp=disabled
	-D gst-plugins-good:shapewipe=disabled
	-D gst-plugins-good:shout2=disabled
	-D gst-plugins-good:smpte=disabled
	-D gst-plugins-good:soup=disabled
	-D gst-plugins-good:spectrum=disabled
	-D gst-plugins-good:taglib=disabled
	-D gst-plugins-good:udp=disabled
	-D gst-plugins-good:v4l2=disabled
	-D gst-plugins-good:videocrop=disabled
	-D gst-plugins-good:videomixer=disabled
	-D gst-plugins-good:wavenc=disabled
	-D gst-plugins-good:ximagesrc=disabled
	-D gst-plugins-good:y4m=disabled
    -D gst-plugins-bad:directfb=disabled
    -D gst-plugins-bad:flite=disabled
    -D gst-plugins-bad:gobject-cast-checks=disabled
    -D gst-plugins-bad:gs=disabled
    -D gst-plugins-bad:iqa=disabled
    -D gst-plugins-bad:isac=disabled
    -D gst-plugins-bad:magicleap=disabled
    -D gst-plugins-bad:onnx=disabled
    -D gst-plugins-bad:openh264=disabled
    -D gst-plugins-bad:openni2=disabled
    -D gst-plugins-bad:opensles=disabled
    -D gst-plugins-bad:tinyalsa=disabled
    -D gst-plugins-bad:voaacenc=disabled
    -D gst-plugins-bad:voamrwbenc=disabled
    -D gst-plugins-bad:wasapi2=disabled
    -D gst-plugins-bad:wasapi=disabled
	-D gst-plugins-bad:fbdev=disabled
	-D gst-plugins-bad:decklink=disabled
	-D gst-plugins-bad:dts=disabled
	-D gst-plugins-bad:faac=disabled
	-D gst-plugins-bad:faad=disabled
	-D gst-plugins-bad:mpeg2enc=disabled
	-D gst-plugins-bad:mplex=disabled
	-D gst-plugins-bad:neon=disabled
	-D gst-plugins-bad:rtmp=disabled
	-D gst-plugins-bad:flite=disabled
	-D gst-plugins-bad:vulkan=disabled
	-D gst-plugins-bad:sbc=disabled
	-D gst-plugins-bad:opencv=disabled
	-D gst-plugins-bad:voamrwbenc=disabled
	-D gst-plugins-bad:x265=disabled
	-D gst-plugins-bad:openexr=disabled
	-D gst-plugins-bad:fbdev=disabled
	-D gst-plugins-bad:decklink=disabled
	-D gst-plugins-bad:dts=disabled
	-D gst-plugins-bad:faac=disabled
	-D gst-plugins-bad:faad=disabled
	-D gst-plugins-bad:libmms=disabled
	-D gst-plugins-bad:mpeg2enc=disabled
	-D gst-plugins-bad:mplex=disabled
	-D gst-plugins-bad:neon=disabled
	-D gst-plugins-bad:rtmp=disabled
	-D gst-plugins-bad:flite=disabled
	-D gst-plugins-bad:vulkan=disabled
	-D gst-plugins-bad:sbc=disabled
	-D gst-plugins-bad:opencv=disabled
	-D gst-plugins-bad:voamrwbenc=disabled
	-D gst-plugins-bad:x265=disabled
	-D gst-plugins-bad:msdk=disabled
	-D gst-plugins-bad:chromaprint=disabled
	-D gst-plugins-bad:avtp=disabled
	-D gst-plugins-bad:kate=disabled
	-D gst-plugins-bad:openexr=disabled
	-D gst-plugins-bad:ladspa=disabled
	-D gst-plugins-bad:ofa=disabled
	-D gst-plugins-bad:microdns=disabled
	-D gst-plugins-bad:openh264=disabled
	-D gst-plugins-bad:resindvd=disabled
	-D gst-plugins-bad:spandsp=disabled
	-D gst-plugins-bad:svthevcenc=disabled
	-D gst-plugins-bad:srtp=disabled
	-D gst-plugins-bad:wildmidi=disabled
	-D gst-plugins-bad:zbar=disabled
	-D gst-plugins-bad:zxing=disabled
	-D gst-plugins-bad:webrtc=disabled
	-D gst-plugins-bad:webrtcdsp=disabled
	-D gst-plugins-bad:openmpt=disabled
	-D gst-plugins-bad:bluez=disabled
	-D gst-plugins-bad:bs2b=disabled
	-D gst-plugins-bad:timecode=disabled
    -D gst-plugins-ugly:gobject-cast-checks=disabled
    -D gst-plugins-ugly:amrnb=disabled
    -D gst-plugins-ugly:amrwbdec=disabled
    -D gst-plugins-ugly:cdio=disabled
    -D gst-plugins-ugly:dvdread=disabled
    -D gst-rtsp-server:gobject-cast-checks=disabled
    -D gst-editing-services:validate=disabled
    )

    # mpeg2dec and x264 are kinda widely used but unavailable as lib32 in Arch repos - enable optionally
    if [ "$_use_lib32_mpeg2dec_and_x264" != "true" ]; then
      meson32_options+=(-D gst-plugins-ugly:mpeg2dec=disabled -D gst-plugins-ugly:x264=disabled)
    fi

    meson "$_nowhere"/Proton/build/gst32 --prefix="$_nowhere/gst" --libdir="lib" --buildtype=release "${meson32_options[@]}"
    meson compile -C "$_nowhere"/Proton/build/gst32
    meson install -C "$_nowhere"/Proton/build/gst32

    # FAudio
    if [ "$_build_faudio" = "true" ]; then
      mkdir -p "$_nowhere"/Proton/build/faudio32/build
      cp -a "$_nowhere"/Proton/FAudio/* "$_nowhere"/Proton/build/faudio32 && cd "$_nowhere"/Proton/build/faudio32/build
      cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$_nowhere"/gst \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_INSTALL_INCLUDEDIR=include/FAudio \
        -DGSTREAMER=ON
      make && make install
    fi

    strip --strip-unneeded "$_nowhere"/gst/lib/*.so
    )
  fi

  cd "$_nowhere"
