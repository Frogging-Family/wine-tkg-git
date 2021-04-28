# Proton-tkg

## PLEASE DO NOT REPORT BUGS ENCOUNTERED WITH THIS AT WINEHQ OR VALVESOFTWARE, REPORT HERE INSTEAD !

This is an addon script for [wine-tkg-git](https://github.com/Frogging-Family/wine-tkg-git/tree/master/wine-tkg-git).

It can create Steamplay compatible wine builds based on wine-tkg-git + additional proton patches and libraries. Wine-staging based? Latest master? Yup, you can.
( **Older than 3.16 wine bases are untested, and some commits or commit ranges might prove problematic with certain combinations of patches.** )

### This is not standalone and requires Steam. If you want a standalone wine build, please see [wine-tkg-git](https://github.com/Frogging-Family/wine-tkg-git/tree/master/wine-tkg-git) instead.


# Quick how-to :

(for dependencies, see the [wiki page](https://github.com/Tk-Glitch/PKGBUILDS/wiki/wine-tkg-git) )


## Download the source :

 * Clone the repo (allows you to use `git pull` to get updates) :
```
git clone https://github.com/Frogging-Family/wine-tkg-git.git
```

## Configuration/customization :

If you want to customize the patches and features of your builds, you can find basic settings in [proton-tkg.cfg](https://github.com/Frogging-Family/wine-tkg-git/blob/master/proton-tkg/proton-tkg.cfg) and advanced settings in [proton-tkg-profiles/advanced-customization.cfg](https://github.com/Frogging-Family/wine-tkg-git/blob/master/proton-tkg/proton-tkg-profiles/advanced-customization.cfg).

You can also create an external configuration file that will contain all settings in a centralized way and survive repo updates. A sample file for this can be found [here](https://github.com/Frogging-Family/wine-tkg-git/blob/master/proton-tkg/proton-tkg-profiles/sample-external-config.cfg). The default path for this file is `~/.config/frogminer/proton-tkg.cfg` and can be changed in `proton-tkg-profiles/advanced-customization.cfg` with the `_EXT_CONFIG_PATH` option.


## Building :

 * We need to get into the proton-tkg dir first:
```
cd proton-tkg
```

### For Arch (and other pacman/makepkg distros) :

**You have two options on pacman based distros. You can either make a pacman package (with a few limitations), or use a more powerful but also less user-friendly way.**


#### Pacman package way :

Using this option will enforce a "proton-tkg-makepkg" naming scheme in Steam, and prevents having multiple versions installed side-by-side. This option also disables steamvr support currently.

 * From the `proton-tkg` directory (where the PKGBUILD is located), run the following command in a terminal to start the building process :
```
makepkg -si
```

#### Unpackaged, vanilla way :

None of the limitations above apply here.

 * From the `proton-tkg` directory (where the PKGBUILD is located), run the following command in a terminal to start the building process :
```
./proton-tkg.sh
```

### For other distros (make sure to check the [wiki page](https://github.com/Tk-Glitch/PKGBUILDS/wiki/wine-tkg-git)) :

 * From the `proton-tkg` directory (where the PKGBUILD is located), running the proton-tkg.sh script will launch the usual wine-tkg-git building process... with extra spice :
```
./proton-tkg.sh
```

### How to uninstall superfluous builds the easy way when not using a pacman package :
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


## The prebuilt DXVK "problem"

By default, proton-tkg will download latest official DXVK release from github. You have nothing to do, it's all good. **However, if you want to build/use a development or modified version of DXVK, it's recommended to use [dxvk-tools](https://github.com/Frogging-Family/dxvk-tools)**

### If you're not using dxvk-tools/can't build DXVK/D9VK :

When `_use_dxvk` is set to `"prebuilt"`, you'll need to put your prebuilt DXVK dlls inside a dxvk folder, in the `external-ressources` folder of proton-tkg:
```
proton-tkg
   |
   |__external-ressources
              |
              |
              --dxvk___x64--> d3d11.dll, dxgi.dll etc.
                    |
                    |__x32--> d3d11.dll, dxgi.dll etc.
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

- Proton-tkg builds will get installed in `~/.steam/root/compatibilitytools.d` directory. If no game is bound to use a specific Proton-tkg build, you can safely delete it. **IT IS HIGHLY RECOMMENDED TO USE THE UNINSTALL FUNCTION OF THE SCRIPT TO REMOVE SUPERFLUOUS BUILDS**
