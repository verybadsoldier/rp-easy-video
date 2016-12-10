# rp-easy-video
Helper tool to manage Retroarch shader and overlay configuration

This is heavily inspired by Floob's rp-video-manager (https://github.com/biscuits99/rp-video-manager) and this is basically a rewrite of it.

It aims to improve:
* Presets can be installed ony a per-system basis. So you can have different presets for different systems
* Generic structure to allow adding more presets without touching code
* Avoid duplication of information. Every preset has a base config file and system can add or overwrite specific variables

## How to add a new Preset

1. Create a Retroarch config file in `presets/my_new_preset.cfg`. This will act as the base config file for the preset.
2. For every supported system add a config file the system subdirectory with the name of the preset. E.g. `presets/snes/my_new_preset.cfg`
This config file may add new variables but it can also change variables existing in the base file. The file may be completely empty so the system will won't change the base file at all.
3. You can add an optional file containing a textual description for your preset. The file should be in the same directory as the base config file but with extension `.txt`. For example `presets/my_new_preset.txt`. 
