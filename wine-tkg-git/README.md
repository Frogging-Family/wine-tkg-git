# Wine to rule them all !

## PLEASE DO NOT REPORT BUGS ENCOUNTERED WITH THIS AT WINEHQ OR VALVESOFTWARE, REPORT HERE INSTEAD !

Wine-tkg is a build-system aiming at easier custom wine builds creation.


# Quick how-to :

(for dependencies, see the [wiki page](https://github.com/Tk-Glitch/PKGBUILDS/wiki/wine-tkg-git) )

## Download the source :


 * Clone the repo (allows you to use `git pull` to get updates) :
```
https://github.com/Frogging-Family/wine-tkg-git.git
```

 * To optionally make use of community patches, you'll want to clone its repo as well:
```
git clone https://github.com/Frogging-Family/community-patches.git
```


## Building on Arch (and other pacman/makepkg distros) :

 * From the `wine-tkg-git` directory (where the PKGBUILD is located), run the following command in a terminal to start the building process :
```
makepkg -si
```


## Building on other distros (make sure to check the [wiki page](https://github.com/Tk-Glitch/PKGBUILDS/wiki/wine-tkg-git) :

 * From the `wine-tkg-git` directory (where the PKGBUILD is located), run the following command in a terminal to start the building process :
```
./non-makepkg-build.sh
```
**Your build will be found in the `PKGBUILD/wine-tkg-git/non-makepkg-builds` dir (independently of the chosen configuration)**


Note for Ubuntu users who want to use docker instead: https://github.com/Tk-Glitch/PKGBUILDS/issues/69#issuecomment-450548800 Thanks to @yuiiio
