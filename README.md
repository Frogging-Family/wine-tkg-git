# Wine to rule them all !

Wine Nightly builds | [Arch Linux](https://github.com/Frogging-Family/wine-tkg-git/actions/workflows/wine-arch.yml) | [Fedora](https://github.com/Frogging-Family/wine-tkg-git/actions/workflows/wine-fedora.yml) | [Ubuntu](https://github.com/Frogging-Family/wine-tkg-git/actions/workflows/wine-ubuntu.yml) |
-------------|--------|--------|-------|

Proton Nightly builds | [Exp Bleeding Edge (glibc 2.35 minimum)](https://github.com/Frogging-Family/wine-tkg-git/actions/workflows/proton-arch-nopackage.yml) |
-------------|--------|--------|-------|
(drop in `/$HOME/.steam/root/compatibilitytools.d/` or, for Ubuntu/Debian based `/$HOME/.steam/compatibilitytools.d/` dir)

## PLEASE DO NOT REPORT BUGS ENCOUNTERED WITH THIS AT WINEHQ OR VALVESOFTWARE, REPORT HERE INSTEAD !

Wine-tkg is a build-system aiming at easier custom wine builds creation. You can now easily get the "plain wine + pba + steam fix" build you've been dreaming about!

It can also make custom Proton builds with its wrapping script: https://github.com/Frogging-Family/wine-tkg-git/tree/master/proton-tkg

**By default, it'll pull current wine/wine-staging git versions. You can target a specific release or commit in the .cfg if needed.**

A comfortable selection of patches is available to you, with some of them being enabled by default for your convenience (see [this sample config file](https://github.com/Frogging-Family/wine-tkg-git/blob/master/wine-tkg-git/wine-tkg-profiles/sample-external-config.cfg) for the full list and details)

An ever evolving selection of staging, experimental and/or hacky patches are also available [in the community-patches](https://github.com/Frogging-Family/community-patches/tree/master/wine-tkg-git)

**Can be built with your own patches - See [README in wine-tkg-git/wine-tkg-userpatches](https://github.com/Frogging-Family/wine-tkg-git/blob/master/wine-tkg-git/wine-tkg-userpatches/README.md) for instructions**

### Generated Wine-tkg sources (staging-based):
 - Wine-tkg : https://github.com/Tk-Glitch/wine-tkg
 - Proton-tkg : https://github.com/Tk-Glitch/wine-proton-tkg

Wine : https://github.com/wine-mirror/wine

Wine-staging : https://github.com/wine-staging/wine-staging

Wine esync : https://github.com/zfigura/wine/tree/esync

Wine fsync : https://github.com/zfigura/wine/tree/fsync

Proton : https://github.com/ValveSoftware/Proton

Wine-pba (Only working correctly up to 3.18 - Force disabled on newer wine bases due to regressions) : https://github.com/acomminos/wine-pba

Thanks to @Firerat and @bobwya for their rebase work :
- https://gitlab.com/Firer4t/wine-pba
- https://github.com/bobwya/gentoo-wine-pba

For Gallium 9 support, use https://github.com/iXit/wine-nine-standalone (available from winetricks and AUR) - Legacy nine support can still be turned on if you're building a 4.1 base or older.
