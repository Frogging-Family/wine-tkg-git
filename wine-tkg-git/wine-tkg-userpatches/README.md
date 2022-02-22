# Wine-tkg userpatches


You can make use of your own patches that aren't available in wine-tkg by putting them in this folder before running makepkg.

You can also symlink them from an external place by running the following command from the PKGBUILD's root dir:
```ln -s /absolute/path/to/your/userpatches/dir/* wine-tkg-userpatches/```

*For example :* `ln -s /home/tkg/.config/frogminer/wine-tkg-userpatches/* wine-tkg-userpatches/`

They need to be diffs against the targeted tree.

To specify the targeted tree, you need to give your patch the appropriate extension :

**!! Patches with unrecognized extension will get ignored !!**


## For wine itself - meaning your patches will be applied to the wine tree AFTER all other patches - This is usually the one you want to use
You can use your own wine patches by giving them the .mypatch extension.

You can also revert wine patches by giving them the .myrevert extension.

*You can also apply/revert patches late (after make_vulkan/make_requests/autoreconf) by giving them the .mylatepatch or .mylaterevert extension following the logic above.*


## For wine staging patchsets - meaning your patches will be applied to the staging patches tree BEFORE being applied to the wine tree
You can use your own wine-staging patches by giving them the .mystagingpatch extension.

You can also revert wine-staging patches by giving them the .mystagingrevert extension.
