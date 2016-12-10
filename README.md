# rp-easy-video
Helper tool to manage Retroarch shader and overlay configuration. This is very BETA currently, so better do a backup before using it :P

This is heavily inspired by Floob's rp-video-manager (https://github.com/biscuits99/rp-video-manager) and it is basically a rewrite of it.

It aims to improve:
* Presets can be installed on a per-system basis. So you can have different presets for different systems.
* Generic structure to allow adding more presets without touching the code.
* Avoid duplication of information. Every preset has a base config file and systems can add or overwrite specific variables.

What it does not (as opposed to the original rp-video-manager):
* Does not modify Retroarch core options config
* Does not modify Retroarch videomodes.cfg
* Does not install/modify other video related files (like Gameboy custom palettes)
* No way to backup or restore previous configurations

## How to add a new Preset

1. Create a Retroarch config file in `presets/my_new_preset.cfg`. This will act as the base config file for the preset.
2. For every supported system add a config file the system subdirectory with the name of the preset. E.g. `presets/snes/my_new_preset.cfg`
This config file may add new variables but it can also change variables existing in the base file. The file may be completely empty so the system will won't change the base file at all.
3. You can add an optional file containing a textual description for your preset. The file should be in the same directory as the base config file but with extension `.txt`. For example `presets/my_new_preset.txt`. 
