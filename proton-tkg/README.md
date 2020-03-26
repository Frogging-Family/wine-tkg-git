# Proton-tkg

## PLEASE DO NOT REPORT BUGS ENCOUNTERED WITH THIS AT WINEHQ OR VALVESOFTWARE, REPORT HERE INSTEAD !

This is an addon script for [wine-tkg-git](https://github.com/Tk-Glitch/PKGBUILDS/tree/master/wine-tkg-git).

It can create Steamplay compatible wine builds based on wine-tkg-git + additional proton patches and libraries. Wine-staging based? Latest master? Yup, you can.
( **Older than 3.16 wine bases are untested.** )

### This is not standalone and requires Steam. If you want a standalone wine build, use [wine-tkg-git](https://github.com/Tk-Glitch/PKGBUILDS/tree/master/wine-tkg-git) instead.

## How to build

### Running the proton-tkg.sh script will launch the usual wine-tkg-git building process... with extra spice.
```
./proton-tkg.sh
```

### How to uninstall superfluous builds the easy way
```
./proton-tkg.sh clean
```
*In its current form, the uninstaller will only handle Proton-tkg builds, and requires that at least one Proton-tkg build is left after uninstalling (meaning you need two beforehand).*


**The following wine-tkg-git options will be enforced (might change in the future):**
- `_EXTERNAL_INSTALL="true"`
- `_EXTERNAL_INSTALL_TYPE="proton"`
- `_EXTERNAL_NOVER="false"`
- `_use_faudio="true"`

**All other wine-tkg-git settings can be tweaked such as wine version, staging, esync, game fixes (etc.) and the userpatches functionality is kept intact.**

You can find all your usual options in the proton-tkg.cfg file. If you create a proton-tkg.cfg file in ~/.config/frogminer dir, it'll be used as an override.

## The prebuilt DXVK/D9VK "problem"

By default, proton-tkg will download latest official DXVK release from github. You have nothing to do, it's all good. **However, if you want to build/use a development or modified version of DXVK, it's recommended to use [dxvk-tools](https://github.com/Tk-Glitch/PKGBUILDS/tree/master/dxvk-tools)**

### If you're not using dxvk-tools/can't build DXVK/D9VK :

When `_use_dxvk` is set to `"prebuilt"`, you'll need to put your prebuilt DXVK dlls inside a dxvk folder, in the root folder of proton-tkg (here):
```
proton-tkg
   |
   |__dxvk___x64--> d3d11.dll, dxgi.dll etc.
          |
          |__x32--> d3d11.dll, dxgi.dll etc.
```

When `_use_d9vk` is set to `"prebuilt"`, you'll need to put your prebuilt D9VK dlls inside a d9vk folder, in the root folder of proton-tkg (here):
```
proton-tkg
   |
   |__d9vk___x64--> d3d9.dll
          |
          |__x32--> d3d9.dll
```

## Special options and builtin features :

Proton-tkg builds are coming with special additional features you can enable/disable post install in the `user_settings.py` file found in your build's folder (`~/.steam/root/compatibilitytools.d/proton_tkg_*`), such as:
- `PROTON_NVAPI_DISABLE` - Option disabled by default, it'll set nvapi and nvapi64 dlls to disabled. It is a common fix for many games.
- `PROTON_WINEDBG_DISABLE` - Option disabled by default, it'll set winedbg.exe to disabled. It's a known fix for GTA V online.
- `PROTON_PULSE_LOWLATENCY` - Option disabled by default, it'll set Pulseaudio latency to 60ms. This usually helps with audio crackling issues on some setups.
- `PROTON_DXVK_ASYNC` - Disabled by default, it'll enable DXVK's async pipecompiler on a compatible DXVK build (official/default DXVK build doesn't support it). Known as the "poe hack", that option *could* be unsafe for anticheats, so beware.
- `PROTON_USE_CUSTOMD3D9` - Disabled by default, it'll enable you to use a custom d3d9 lib that's not already available in proton-tkg (namely d9vk and wined3d), like Gallium9 for example.
- `PROTON_WINETRICKS` - Enabled by default, the built-in winetricks integration will show a popup on game launch asking if you want to run winetricks (against your game's prefix). It requires that you have both the `winetricks` and `tk` (`python3-tk` on some distros) packages installed.

You can also change their default values before building in your `proton-tkg.cfg` file.


## Other things to know :

- Proton doesn't like running games from NTFS. Consider symlinking your compatdata dir(s) (usually found in /SteamApps) to some place on an EXT4 partition if you want to play games from a NTFS partition.

- Proton-tkg **can** handle 32-bit prefixes. However you'll have to create such a prefix by hand as the Steam client doesn't offer such an option. Also, that prefix will have to be deleted if you want to use an official Proton build with the game bound to it.

- In the userpatches folder, you'll find three patches I decided against merging in the master patch for proton-tkg. You can put them in wine-tkg-git userpatches dir if you want to use them. They might not apply cleanly on older wine bases.

- Proton-tkg builds will get installed in `~/.steam/root/compatibilitytools.d` directory. If no game is bound to use a specific Proton-tkg build, you can safely delete it. **IT IS HIGHLY RECOMMENDED TO USE THE UNINSTALL FUNCTION OF THE SCRIPT TO REMOVE SUPERFLUOUS BUILDS**

If you end up removing a Proton build (not necessarily -tkg) that's bound to a game, you can fix the issue by editing your `~/.steam/root/config/config.vdf` file and replacing the deleted build reference name with one from a currently installed build.
