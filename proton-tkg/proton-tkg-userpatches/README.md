# Proton-tkg userpatches


You can make use of your own patches to the Proton tree by putting them in this folder before running proton-tkg.sh/makepkg.

You can also symlink them from an external place by running the following command from proton-tkg's root dir:
```ln -s /absolute/path/to/your/userpatches/dir/* proton-tkg-userpatches/```

*For example :* `ln -s /home/tkg/.config/frogminer/proton-tkg-userpatches/* proton-tkg-userpatches/`

They need to be diffs against the targeted tree.

** Those patches need to target the Proton tree directly and not wine. For wine patches handling, see https://github.com/Tk-Glitch/PKGBUILDS/tree/master/wine-tkg-git/wine-tkg-userpatches**

You need to give your patch the appropriate extension :

**!! Patches with unrecognized extension will get ignored !!**

You can use your own proton patches by giving them the .myprotonpatch extension.

You can also revert proton patches by giving them the .myprotonrevert extension.
