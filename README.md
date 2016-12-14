# rp-easy-video
Helper tool to create and manage Retroarch configurations to configure shaders and overlays in RetroPie.

This is heavily inspired by Floob's rp-video-manager (https://github.com/biscuits99/rp-video-manager) and it is basically a rewrite of it.

It can do two things:

1. Create Retroarch configuration files (retroarch.cfg) for all systems. These configuration files are composed of a shader and an overlay that you can choose.
2. Also it can install per-ROM config files for arcade systems (like MAME) that can set-up shaders and overlays on a pre-ROM basis. For example the fantastic overlays of John Merrit are included and ready to use.

The tool is meant to be easily extensible: New shaders and overlays can be added without touch the code.
It features:
* Configurations be installed on a per-system basis. So you can have different configurations for different systems.
* Generic structure to allow adding more shaders and overlays without touching the code.
* Avoid duplication of information: Each overlay has a base configuration file and systems can add or overwrite specific variables.

What it does not (as opposed to the original rp-video-manager):
* Does not modify Retroarch core options config
* Does not modify Retroarch videomodes.cfg
* Does not install/modify other video related files (like Gameboy custom palettes)
* No way to backup or restore previous configurations

*NOTE:* Since currently in RetroPie the directory structure on RaspberryPi does differ from the directory structure for other platforms this tool does at the moment not work on RaspberryPis. I have some ideas how to do this but since I am not using a RaspberryPi myself anymore I would only implement it if there is any interest in this.
## How to Install ##
Log in with an SSH shell to your RetroPie. Then download the tool typing this:
```
git clone https://github.com/verybadsoldier/rp-easy-video.git
```

Then go to the create directory and start it:
```
cd rp-easy-video
./easy-video.sh
```

Then you need to install the resources (new shaders and overlays) that come bundled with rp-easy-video. To do this choose `Resources` from the main menu and then `Install Resource`.
This will install shaders to `/opt/retropie/configs/all/retroarch/shaders/easy-video` and overlays to `/opt/retropie/configs/all/retroarch/overlay/easy-video`.

## How to configure a System ##
Configuring a system means that you select a combination of a shader and and overlay. Then you will install this configuration to a system (or all systems).
It will create a file `retroarch.cfg` and copy it to the directory of the system you choose: ` /opt/retropie/configs/<sys>`

1. From the main menu choose `Configure system(s)`
2. Now you are in the shader menu. Pick a shader from the list you want to use (you can also choos `None`to not use a shader)
3. Now in the overlay pick your overlay. Keep in mind that overlays often have to be hand-tweaked for every system to match their specific screen coordinates. So when choosing an overlay only from that overlays supported systems will be availalbe in the next step.
4. Select the system for which your selected configuration should be installed for. You can either select a single system or select `<All>` to install it for all systems.

## How to configure Arcades per-ROM ##
Arcade per-ROM configs are shader and/or overlays that get applied to each machine (each game) individually. The included configs only cover a small amount of games. For the other games the usual system configuration applies.
The per-ROM configs are copied directly into the ROM folder (e.g. `/home/pi/RetroPie/roms/mame-libretro`).

1. From the main menu choose `Arcade per-ROM configs`
2. Select your desired config from the list
3. Choose the target system

NOTE: if the per-ROM configs do not cover some settings (e.g. shaders when you pick `john.merrit-no-shader` config) then still the shader settings from the system apply. So you could freely choose a shader using `Configure system(s)` for `mame-libretro` and then still apply the John Merrit Arcade overlays separately.

## How to add a new Shaders

1. Create a Retroarch config file in `shaders/my_new_shader.cfg`. The file should contain all the relevant config settings that are relevant for this shader configuration.

## How to add a new Overlay

1. Create a Retroarch config file in `overlays/my_new_overlay.cfg`. This will act as the base config file for the overlay.
2. For every supported system add a config file int the system subdirectory with the name of the overlay. E.g. `overlays/snes/my_new_overlay.cfg`
This config file may add new variables but it can also change variables existing in the base file. The file may be completely empty so the system will won't change the base file at all.
This is usually used to adapt the custom viewport cooridnates  for the system to match the used overlay bitmap dimensions.

## How to add a new Arcade per-ROM Configuration

1. Create a new directory in the directory `arcade-per-rom` (e.g. `arcade-per-rom/my-new-arcade-config`)
2. Add Retroarch ROM config files to the directory. These files will be copied to the ROM directory upon installation. So the files should match the ROM filename with an additional extension `.cfg`.
3. You can add an optional file containing a textual description for your overlay. The file should be in the same directory as the base config file but with extension `.txt`. For example `presets/my_new_preset.txt`. 
