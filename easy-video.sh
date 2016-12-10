#!/bin/bash

source ./inifuncs.sh

clear

SELF_NAME="easy-video"
RP_CFG_DIR="/opt/retropie/configs"

RA_BASE_DIR="/opt/retropie/emulators/retroarch"
RA_SHADER_DIR="${RA_BASE_DIR}/shader"
RA_OVERLAYS_DIR="${RA_BASE_DIR}/overlays"

SYSTEMS=$(find presets/* -type d ! -name all | xargs basename -a)

function uninstall_resources() {
    rm -rf "${RA_OVERLAYS_DIR}/${SELF_NAME}"
    rm -rf "${RA_SHADER_DIR}/${SELF_NAME}"
}

function install_resources() {
    uninstall_resources
    
    cp -r "./resources/shader" "${RA_SHADER_DIR}/${SELF_NAME}"
    cp -r "./resources/overlays" "${RA_OVERLAYS_DIR}/${SELF_NAME}"
}

function menu_resources() {
    while :
     do
       echo "Resources Menu"
       PS3=$CONFIGPROMPT
       select option1 in "Install Resources" "Uninstall Resources" Quit
       do
         case $REPLY in
           1) # Install Resources
              install_resources
              echo "Installation complete"
              break
              ;;
           2) # Uninstall Resources
              uninstall_resources
              break  #  Breaks out of the select, back to the mango loop.
              ;;                                   
           3) # Quit
              break 2  # Breaks out 2 levels, the select loop plus the mango while loop, back to the main loop.
              ;;                 
           *) # always allow for the unexpected
              echo "Unknown mango operation [${REPLY}]"
              break
              ;;
         esac
       done
     done
     break
}


function install_preset() {
    local preset="$1"
    local sys="$2"
    
    [[ ! -d "${RP_CFG_DIR}/${sys}" ]] && return 1
    
    echo "Installing preset '${preset}' for system '${sys}'"
    
    local dest_cfg="${RP_CFG_DIR}/${sys}/retroarch.cfg"
 
    echo "Copying './presets/${preset}.cfg' to '${dest_cfg}'"
    cp "./presets/${preset}.cfg" "${dest_cfg}"
    
    # check if we have system specific parameters
    declare -A sys_values
    local sys_conf="presets/${sys}/${preset}.cfg"
    echo "Checking for system sepcific settings: '${sys_conf}'"
    if [[ -f "${sys_conf}" ]]; then
        echo "Found system sepcific settings: '${sys_conf}'"
        
        iniConfig ' = ' '"' "${sys_conf}"
        local tags=($(iniGetTagsAll))
        for tag in ${tags[@]}; do
            iniGet "${tag}"
            sys_values[${tag}]=${ini_value}
        done
    fi
    
    iniConfig ' = ' '"' "$dest_cfg"
    iniSet "input_remapping_directory" "/opt/retropie/configs/${sys}/"
    
    for key in "${!sys_values[@]}"; do 
        iniSet "${key}" "${sys_values[${key}]}"
    done
}

function get_presets_files() {
    find presets/ -maxdepth 1 -name *.cfg
}

function get_presets() {
    local presets=$(get_presets_files)
    echo ${presets} | xargs -n 1 basename | sed s/\.cfg$//g
}

function get_supported_systems() {
    local preset=$1
    rm /tmp/log.txt
    echo "${preset}" >> /tmp/log.txt
    if [[ -f "presets/all/${preset}.cfg" ]]; then
        echo "ALL" >> /tmp/log.txt
        echo ${SYSTEMS}        
    else
        local supp_systems=()
        for system in ${SYSTEMS[@]}; do
            echo "Check file: presets/${system}/${preset}.cfg" >> /tmp/log.txt
            if [[ -f "presets/${system}/${preset}.cfg" ]]; then
                echo "Found system: ${system}" >> /tmp/log.txt
                supp_systems+=("${system}")
            fi
        done
        echo ${supp_systems[@]}
    fi
}

function menu_install_preset() {
    local preset=$1
    local supp_systems=($(get_supported_systems "${preset}"))
    while :
     do
       PS3="Choose system (${preset}) to install:"
       select option1 in "<Quit>" All ${supp_systems[@]}
       do
         case $REPLY in
           1) break 2;;
           2) 
              for sys in ${supp_systems[@]}; do
                install_preset "${preset}" "${sys}"
              done
              ;;
           *) # always allow for the unexpected
              REPLY=$((${REPLY} - 3))
              install_preset "${preset}" "${supp_systems[${REPLY}]}"
              break
              ;;
         esac
       done
    done
    break
}

function menu_presets() {
    local presets=($(get_presets))
    while :
     do
       echo "Choose Preset"
       PS3=$CONFIGPROMPT
       select option1 in "<Quit>" ${presets[@]}
       do
         case $REPLY in
           1) break 2;;
           *) # always allow for the unexpected        
              REPLY=$((${REPLY} - 2))
              echo "idx: ${REPLY}"
              local sel_preset=${presets[${REPLY}]}
              echo "PRESET: ${sel_preset}"
              menu_install_preset "${sel_preset}"
              break
              ;;
         esac
       done
     done
     break
}

while :
do
    echo "Easy Video Main Menu"
    PS3=$MAINPROMPT  # PS3 is the prompt for the select construct.

    select option in Resources Presets Quit
    do
    case $REPLY in
        1) menu_resources;;
        2) menu_presets;;
        3) break 2;;
        *) # always allow for the unexpected
           echo "Unknown mango operation [${REPLY}]"
           break
           ;;
    esac
    done
done

exit 0
$
