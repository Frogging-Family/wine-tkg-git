#!/bin/sh

files=$1
prefix=$2
output=$3
name=$4
pkgver=$5
pkgname=$6
tmpDir=/tmp/debian-package

# TODO: Support different prefixes
if [ "$prefix" != "/usr" ]; then
    echo "Sorry, $prefix as prefix is not supported yet in wine-tkg packaging for Debian on Arch"
    exit
fi

# Filesystem that can be found in $files
lib32name="lib32"
lib64name="lib"

rm -rf $tmpDir || true
mkdir $tmpDir

# Package format version number
echo "2.0" > $tmpDir/debian-binary

# TODO FIX: Make wine64-tkg the default as "wine64", the problem is it causes wine to complain about wine64
# Make wine-tkg and wine64-tkg the default
mv "$files"/usr/bin/wine "$files"/usr/bin/_wine
#mv "$files"/usr/bin/wine64 "$files"/usr/bin/_wine64
cp "$files"/usr/bin/wine-tkg "$files"/usr/bin/wine
#cp "$files"/usr/bin/wine64-tkg "$files"/usr/bin/wine64

# Move the resulting build folders to match debian's filesystem
mkdir "$files"/usr/lib32_
cp -r "$files"/usr/$lib32name/* "$files"/usr/lib32_
rm -r "$files"/usr/$lib32name
mkdir "$files"/usr/lib64_
cp -r "$files"/usr/$lib64name/* "$files"/usr/lib64_
rm -r "$files"/usr/$lib64name
mkdir "$files"/usr/lib
mkdir "$files"/usr/lib/wine
cp -r "$files"/usr/bin/* "$files"/usr/lib/wine
mkdir "$files"/usr/lib/i386-linux-gnu
mkdir "$files"/usr/lib/x86_64-linux-gnu
cp -r "$files"/usr/lib32_/* "$files"/usr/lib/i386-linux-gnu && rm -r "$files"/usr/lib32_/*
cp -r "$files"/usr/lib64_/* "$files"/usr/lib/x86_64-linux-gnu && rm -r "$files"/usr/lib64_/*
rm -r "$files"/usr/lib32_
rm -r "$files"/usr/lib64_

# Files
tar --exclude='.[^/]*' -czf $tmpDir/data.tar.gz -C "$files" ./ >> /dev/null

# Revert "Move the resulting build folders to match debian's filesystem"
mkdir "$files"/usr/lib64_
mkdir "$files"/usr/lib32_
cp -r "$files"/usr/lib/x86_64-linux-gnu/* "$files"/usr/lib64_
cp -r "$files"/usr/lib/i386-linux-gnu/* "$files"/usr/lib32_
rm -r "$files"/usr/lib
mkdir "$files"/usr/$lib64name
mkdir "$files"/usr/$lib32name
cp -r "$files"/usr/lib64_/* "$files"/usr/$lib64name
cp -r "$files"/usr/lib32_/* "$files"/usr/$lib32name
rm -r "$files"/usr/lib64_
rm -r "$files"/usr/lib32_

# Revert "Make wine-tkg and wine64-tkg the default"
#rm "$files"/usr/bin/wine64
rm "$files"/usr/bin/wine
#mv "$files"/usr/bin/_wine64 "$files"/usr/bin/wine64
mv "$files"/usr/bin/_wine "$files"/usr/bin/wine

# Control file
mkdir $tmpDir/control
cat >$tmpDir/control/control <<EOL
Package: ${pkgname}
Version: ${pkgver}
Architecture: all
Maintainer: Tk-Glitch <ti3nou@gmail.com>
Homepage: https://github.com/Frogging-Family/wine-tkg-git
Provides: ${pkgname}, wine, wine-development, wine-staging, libwine, fonts-wine, wine32, wine64
Conflicts: wine, libwine, fonts-wine, wine32, wine64
Replaces: wine, wine-development, wine-staging, libwine, fonts-wine, wine32, wine64
License: LGPL
Depends: libc6 (>= 2.17), libfontconfig1 (>= 2.11), libfreetype6 (>= 2.2.1), libncurses5 (>= 6), libasound2 (>= 1.0.16), libgcc1 (>= 1:3.0), libglu1-mesa | libglu1, liblcms2-2 (>= 2.2+git20110628), libldap-2.4-2 (>= 2.4.7), libmpg123-0 (>= 1.6.2), libopenal1 (>= 1.14), libpcap0.8 (>= 0.9.8), libpulse0 (>= 0.99.1), libx11-6, libxext6, libxml2 (>= 2.9.0), ocl-icd-libopencl1 | libopencl1, ocl-icd-libopencl1 (>= 1.0) | libopencl-1.1-1, zlib1g (>= 1:1.1.4)
Installed-Size: $(du -sb ${files} | awk '{printf "%1.0f\n",$1/1024}')
Description: This "Wine to rule them all" package is the result of wine-tkg build system found online. Some variants of it can be found in lutris runners. 🐸🐸🐸🐸🐸🐸🐸🐸
EOL
tar czf $tmpDir/control.tar.gz -C $tmpDir/control ./ >> /dev/null
rm -r $tmpDir/control

# Create .deb file
prev=$PWD
cd $tmpDir
ar -r $name debian-binary control.tar.gz data.tar.gz &> /dev/null
# TODO: better solution
cp $name "$output"
cd $prev

rm -rf $tmpDir
cd ..