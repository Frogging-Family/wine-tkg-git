# Wine-tkg build system modified for Roblox needs.

**NOTE**: If your builds are failing, check `customization.cfg` for good measures.

### Purpose: This guide outlines building and using a Wine version specifically optimized for Roblox, enhancing its performance.

## Prerequisites:

  - git

## Build Instructions:

**1.** Clone the repository:

   ```git clone https://github.com/AvoMC/wine-rbx-tkg-git```

**2.** Navigate to the build directory:

   ```cd wine-rbx-tkg-git/wine-tkg-git```

**3.** Review and customize configuration (optional, but heavily recommended):

   Examine the ```customization.cfg``` file for potential adjustments.

**4.** Initiate the build process:

```./non-makepkg-build.sh```
        
#### Build time depends on your hardware capabilities.

## Using the Built Wine with Vinegar:

**5.** Locate the build directory:

    ```cd wine-rbx-tkg-git/wine-tkg-git/non-makepkg-builds/```

**6.** Copy the build path:

```
realpath *
```

**7.** Modify Vinegar configuration:

Open your Vinegar configuration file (usually ~/.config/vinegar/config.toml).
Add the following line at the beginning, replacing insert path here with the copied build path:

    ```wineroot = "insert path here"```


**8.** Launch Roblox games:

With the configured Wine, Roblox games should now function as intended.
