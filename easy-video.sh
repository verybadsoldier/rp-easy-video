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
    echo "Deleting resources from ${RA_OVERLAYS_DIR}/${SELF_NAME}"
    rm -rf "${RA_OVERLAYS_DIR}/${SELF_NAME}"

    echo "Deleting resources from ${RA_SHADER_DIR}/${SELF_NAME}"
    rm -rf "${RA_SHADER_DIR}/${SELF_NAME}"
}

function install_resources() {
    uninstall_resources
    
    echo "Installing shaders to ${RA_SHADER_DIR}/${SELF_NAME}"
    cp -r "./resources/shader" "${RA_SHADER_DIR}/${SELF_NAME}"

    echo "Installing overlays to ${RA_OVERLAYS_DIR}/${SELF_NAME}"
    cp -r "./resources/overlays" "${RA_OVERLAYS_DIR}/${SELF_NAME}"
}

function menu_resources() {
    while :
    do
       echo ""
       echo "-= Resources Menu =-"
       PS3="Choose: "
       select option1 in "Install Resources" "Uninstall Resources" Back
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
           3) # Back
              break 3
              ;;                 
           *) # always allow for the unexpected
              echo "Unknown mango operation [${REPLY}]"
              break
              ;;
         esac
       done
    done
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
    echo "-= Install Preset =-"
    echo "Selected Preset: ${preset}"
    
    local descr_file="presets/${preset}.txt"
    local descr
    [[ -f "$descr_file" ]] && descr=$(cat "${descr_file}")
    
    [[ ! -z ${descr} ]] && echo "Description: ${descr}"
    
    while : 
    do
        PS3="Choose target system: "
        select option1 in "<- Back" "<All>" ${supp_systems[@]}
        do
            case $REPLY in
            1) 
                break 2
                ;;
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
}

function menu_presets() {
    local presets=($(get_presets))
    while : 
    do
        echo ""
        echo "-= Preset Menu =-"
        echo "Shows a list of all available presets and let you install one"
        PS3="Choose preset to install: "
        select option1 in "<- Back" ${presets[@]}
        do
            case $REPLY in
            1) 
                break 3
                ;;
            *)  
                if [[ ${REPLY} -gt $(( ${#presets[@]} + 1 )) ]]; then
                    echo "Unknown preset: [${REPLY}]. Choose again..."
                    break
                fi
                REPLY=$((${REPLY} - 2))
                menu_install_preset "${presets[${REPLY}]}"
                break
                ;;
            esac
        done
    done
}

while :
do
    echo ""
    echo "-= Easy Video Main Menu =-"
    PS3="Choose: "

    select option in Resources Presets Quit
    do
        case $REPLY in
            1) 
                menu_resources
                ;;
            2)  
                menu_presets
                ;;
            3) 
                break 2
                ;;
            *) 
               echo "Invalid input: [${REPLY}]"
               break
               ;;
        esac
    done
done

exit 0
$
