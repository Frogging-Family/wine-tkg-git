# Proton-tkg userpatches


You can make use of your own patches to the Proton, dxvk and vkd3d-proton trees by putting them in this folder before running proton-tkg.sh or makepkg.

You can also symlink them from an external place by running the following command from proton-tkg's root dir:
```ln -s /absolute/path/to/your/userpatches/dir/* proton-tkg-userpatches/```

*For example :* `ln -s /home/tkg/.config/frogminer/proton-tkg-userpatches/* proton-tkg-userpatches/`

They need to be diffs against the targeted tree.


You need to give your patch the appropriate extension :

**!! Patches with unrecognized extension will get ignored !!**

### Proton tree
** Those patches need to target the Proton tree directly and not wine. For wine patches handling, see https://github.com/Frogging-Family/wine-tkg-git/tree/master/wine-tkg-git/wine-tkg-userpatches**

- You can use your own proton patches by giving them the .myprotonpatch extension.
- You can also revert proton patches by giving them the .myprotonrevert extension.

### DXVK tree
- You can use your own dxvk patches by giving them the .mydxvkpatch extension.
- You can also revert dxvk patches by giving them the .mydxvkrevert extension.

### vkd3d-proton tree
- You can use your own vkd3d-proton patches by giving them the .myvkd3dpatch extension.
- You can also revert vkd3d-proton patches by giving them the .myvkd3drevert extension.
