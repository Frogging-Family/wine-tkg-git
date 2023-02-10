#Settings here will take effect for all games run in this Proton version.

user_settings = {
    #By default, logs are saved to $HOME/steam-<STEAM_GAME_ID>.log, overwriting any previous log with that name.
    #Log directory can be overridden with $PROTON_LOG_DIR.

    #Wine debug logging
#    "WINEDEBUG": "+timestamp,+pid,+tid,+seh,+debugstr,+loaddll,+mscoree",

    #DXVK debug logging
#    "DXVK_LOG_LEVEL": "info",

    #wine-mono debug logging (Wine's .NET replacement)
#    "WINE_MONO_TRACE": "E:System.NotImplementedException",
#    "MONO_LOG_LEVEL": "info",

    #Set DXVK custom config path
#    "DXVK_CONFIG_FILE": "",

    #Enable DXVK's HUD
#    "DXVK_HUD": "devinfo,fps",

    #Enable AMD FSR
     "WINE_FULLSCREEN_FSR": "1",
     "WINE_FULLSCREEN_FSR_STRENGTH": "2",

    #Write the command proton sends to wine for targeted prefix (/prefix/path/launch_command) - Helpful to track bound executable
    "PROTON_LOG_COMMAND_TO_PREFIX": "1",

    #Alternative way to run executables directly with wine binary instead of using steam.exe. This is the preffered way when using proton standalone.
#    "PROTON_STANDALONE_START": "1",

    #Enable nvapi support through nvidia provided nvngx.dll (Requires nvidia driver 470+) - Needed for DLSS support
#    "PROTON_ENABLE_NVAPI": "1",

    #Disable nvapi and nvapi64
    "PROTON_NVAPI_DISABLE": "1",

    #Pass "--use-gl=osmesa" to the command line. Fixes various launchers showing up with a black window (Star Citizen, Warframe, etc..). Might give poor perf on native opengl games, so disable in case of issues.
    "PROTON_GL_OSMESA": "1",

    #Set a wine override to disable libglesv2. Fixes various launchers showing up with a black window (Star Citizen, Warframe, etc..). Alternative to running an app with `--use-gl=osmesa`, but more extreme.
    #Known to break at least the Rockstar Games Launcher, so only use if the PROTON_GL_OSMESA option above doesn't fix your issue.
    #We used to have a revert for that, but it would only affect upstream builds. This is a more universal solution - https://bugs.winehq.org/show_bug.cgi?id=44985
#    "PROTON_GLES2_DISABLE": "1",

    #Disable winedbg
    "PROTON_WINEDBG_DISABLE": "1",

    #Disable conhost
    "PROTON_CONHOST_DISABLE": "1",

    #Disable IMAGE_FILE_LARGE_ADDRESS_AWARE override - In case it breaks your (32-bit) game - System Shock 2 is known to break with LAA enabled
#    "PROTON_DISABLE_LARGE_ADDRESS_AWARE": "1",

    #Reduce Pulse Latency
    "PROTON_PULSE_LOWLATENCY": "1",

    #Enable Winetricks prompt on game launch
#    "PROTON_WINETRICKS": "1",

    #Enable seccomp-bpf filter to emulate native syscalls, required for some DRM protections to work. Requires staging on proton-tkg.
#    "PROTON_USE_SECCOMP": "1",

    #Disable support for memory write watches in ntdll. This is a very dangerous hack and should only be applied if you have verified that the game can operate without write watches.
    #This improves performance for some very specific games (e.g. CoreRT-based games).
#    "PROTON_NO_WRITE_WATCH": "1",

    #Spoof d3d12 feature level supported by vkd3d. Needed for some d3d12 games to work.
    "VKD3D_FEATURE_LEVEL": "12_0",

    #Use OpenGL-based wined3d for d3d11/d3d10/d3d9 instead of Vulkan-based DXVK & D9VK
#    "PROTON_USE_WINED3D": "1",

    #Use OpenGL-based wined3d for d3d11/10 only (keeping D9VK enabled). Comment out to use Vulkan-based DXVK instead.
#    "PROTON_USE_WINED3D11": "1",

    #Enable custom d3d9 dll usage. This is the option you want to enable to use Gallium 9. Builtin D9VK won't be used with this option enabled.
#    "PROTON_USE_CUSTOMD3D9": "1",

    #Use OpenGL-based wined3d for d3d9 only (keeping DXVK enabled). Comment out to use Vulkan-based D9VK or custom d3d9 dll instead.
    "PROTON_USE_WINED3D9": "1",

    #Use Wine DXGI instead of DXVK's. This is needed to make use of VKD3D when DXVK is enabled. It will prevent the use of DXVK's DXGI functions.
#    "PROTON_USE_WINE_DXGI": "1",

    #Disable d3d11 entirely !!!
#    "PROTON_NO_D3D11": "1",

    #Disable d3d10 entirely !!!
#    "PROTON_NO_D3D10": "1",

    #Disable d3d9 entirely !!!
#    "PROTON_NO_D3D9": "1",

    #Disable eventfd-based in-process synchronization primitives
#    "PROTON_NO_ESYNC": "1",

    #Disable futex-based in-process synchronization primitives
#    "PROTON_NO_FSYNC": "1",

    #Disable futex2-based in-process synchronization primitives
#    "PROTON_NO_FUTEX2": "1",

    #Disable support for fast (one syscall per NT syscall) synchronization primitives using the winesync driver in the kernel
#    "PROTON_NO_NTSYNC": "1",

    #Enforce driver shader cache path when Steam's shader pre-caching is disabled
#    "PROTON_BYPASS_SHADERCACHE_PATH": "",
}
