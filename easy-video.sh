#!/bin/bash

source ./inifuncs.sh

clear

SELF_NAME="easy-video"
RP_CFG_DIR="/opt/retropie/configs"

RA_BASE_DIR="/opt/retropie/emulators/retroarch"
RA_SHADER_DIR="${RA_BASE_DIR}/shader"
RA_OVERLAYS_DIR="${RA_BASE_DIR}/overlays"

RP_ROMS_DIR="/home/${USER}/RetroPie/roms"

SYSTEMS=$(find overlays/* -type d ! -name all | xargs basename -a | sort)

SYSTEMS_ARCADE=(arcade mame-libretro mame-mame4all fba mame-advmame)

function uninstall_resources() {
    echo "Deleting resources from ${RA_OVERLAYS_DIR}/${SELF_NAME}"
    rm -rf "${RA_OVERLAYS_DIR}/${SELF_NAME}"

    echo "Deleting resources from ${RA_SHADER_DIR}/${SELF_NAME}"
    rm -rf "${RA_SHADER_DIR}/${SELF_NAME}"
}

function get_systems_arcade() {
    for sys in ${SYSTEMS_ARCADE}; do
        [[ -d "${RP_ROMS_DIR}/${sys}" ]] && echo "${sys}"
    done
}

function get_overlay_files() {
    find overlays/ -maxdepth 1 -name *.cfg | sort
}

function get_overlays() {
    local overlays=$(get_overlay_files)
    echo ${overlays} | xargs -n 1 basename | sed s/\.cfg$//g
}

function get_shaders() {
    find shaders -type f -exec basename {} \; | sed s/\.cfg$//g | sort
}

function get_presets_arcade() {
    find presets-arcade -type d -exec basename {} \; | sort
}

function get_supported_systems() {
    local overlay="$1"
    if [[ "${overlay}" == "None" || -f "overlays/all/${overlay}.cfg" ]]; then
        echo ${SYSTEMS}
    else
        local supp_systems=()
        for system in ${SYSTEMS[@]}; do
            if [[ -f "overlays/${system}/${overlay}.cfg" ]]; then
                supp_systems+=("${system}")
            fi
        done
        echo ${supp_systems[@]}
    fi
}

function install_resources() {
    uninstall_resources
    
    echo "Installing shaders to ${RA_SHADER_DIR}/${SELF_NAME}"
    cp -r "./resources/shader" "${RA_SHADER_DIR}/${SELF_NAME}"

    echo "Installing overlays to ${RA_OVERLAYS_DIR}/${SELF_NAME}"
    cp -r "./resources/overlays" "${RA_OVERLAYS_DIR}/${SELF_NAME}"
}

function merge_config() {
    local src="$1"
    local dest="$2"
    
    echo "Merging config - In: ${src} Out: ${dest}"
    declare -A values
    iniConfig ' = ' '"' "${src}"
    local tags=($(iniGetTagsAll))
    for tag in ${tags[@]}; do
        iniGet "${tag}"
        values[${tag}]=${ini_value}
    done
    
    iniConfig ' = ' '"' "$dest"
    for key in "${!values[@]}"; do 
        iniSet "${key}" "${values[${key}]}"
    done
}

function install_config() {
    local shader="$1"
    local overlay="$2"
    local sys="$3"
    

    echo "Installing config:"
    printf "\tShader: ${shader}\n"
    printf "\tOverlay: ${overlay}\n"
    printf "\tSystem: ${sys}\n"
    
    [[ ! -d "${RP_CFG_DIR}/${sys}" ]] && return 1
    [[ "${shader}" == "None" ]] && [[ "${overlay}" == "None" ]] && return 2
    
    local dest_cfg="${RP_CFG_DIR}/${sys}/retroarch.cfg"

    echo "Creating config: '${dest_cfg}'"

    # create empty config
    cat > "${dest_cfg}" << _EOF_
# Settings made here will only override settings in the global retroarch.cfg if placed above the #include line

input_remapping_directory = "/opt/retropie/configs/${sys}/"

#include "/opt/retropie/configs/all/retroarch.cfg"
_EOF_

    if [[ "${shader}" != "None" ]]; then
        echo "Merging config from 'shaders/${shader}.cfg'"
        merge_config "shaders/${shader}.cfg" "${dest_cfg}"
    fi

    if [[ "${overlay}" != "None" ]]; then
        echo "Merging config from 'overlays/${overlay}.cfg'"
        merge_config "overlays/${overlay}.cfg" "${dest_cfg}"
        
        # check if we have system specific parameters
        declare -A sys_values
        local sys_conf="overlays/${sys}/${overlay}.cfg"
        echo "Checking for system sepcific settings: '${sys_conf}'"
        if [[ -f "${sys_conf}" ]]; then
            echo "Found system sepcific settings: '${sys_conf}'"
            merge_config "${sys_conf}" "${dest_cfg}"
        fi
    fi
    
#    echo '#include "/opt/retropie/configs/all/retroarch.cfg"' >> "$dest_cfg"
#    iniConfig ' = ' '"' "$dest_cfg"
#    iniSet "input_remapping_directory" "/opt/retropie/configs/${sys}/"
}

function install_preset_arcade() {
    local preset="$1"
    local sys="$2"

    echo "Installing arcade preset '${preset}' for system '${sys}'"
    
    local dest_dir="${RP_ROMS_DIR}/${sys}"
 
    echo "Deleting all existing .cfg files in '${dest_dir}'"
    rm "${dest_dir}/"*.cfg
    
    echo "Copying './presets-arcade/${preset}' to '${dest_dir}'"
    cp presets-arcade/"${preset}"/* "${dest_dir}"
}

function menu_install() {
    local shader=$1
    local overlay=$2
    local supp_systems=($(get_supported_systems "${overlay}"))

    while : 
    do
        echo ""
        echo "-= Install Configuration =-"
        echo "Selected Shader: ${shader}"
        echo "Selected Overlay: ${overlay}"
        echo ""
        
        PS3="Choose target system: "
        select option1 in "<- Back" "<All>" ${supp_systems[@]}
        do
            case $REPLY in
            1) 
                break 2
                ;;
            2) 
                for sys in ${supp_systems[@]}; do
                    install "${preset}" "${sys}"
                done
                break
                ;;
            *) # always allow for the unexpected
                REPLY=$((${REPLY} - 3))
                install_config "${shader}" "${overlay}" "${supp_systems[${REPLY}]}"
                break
                ;;
            esac
        done
    done
}

function menu_overlay() {
    local shader="$1"
    local overlays=('None')
    overlays+=($(get_overlays))
    while : 
    do
        echo ""
        echo "-= Overlay Menu =-"
        echo "Shows a list of all available presets and let you install one"
        PS3="Choose overlay: "
        select option1 in "<- Back" ${overlays[@]}
        do
            case $REPLY in
            1) 
                break 3
                ;;
            *)  
                if [[ ${REPLY} -gt $(( ${#overlays[@]} + 1 )) ]]; then
                    echo "Unknown preset: [${REPLY}]. Choose again..."
                    break
                fi
                REPLY=$((${REPLY} - 2))
                
                local overlay="${overlays[${REPLY}]}"
                if [[ "${shader}" == "None" && "${overlay}" == "None" ]]; then
                    echo "Both shader and overlay cannot be None!"
                    break
                fi
                menu_install "${shader}" "${overlay}"
                break
                ;;
            esac
        done
    done
}

function menu_shaders() {
    local shaders=('None')
    shaders+=($(get_shaders))
    while : 
    do
        echo ""
        echo "-= Shaders Menu =-"
        echo "First step is to choose the shader you want to use."
        PS3="Choose shader: "
        select option1 in "<- Back" ${shaders[@]}
        do
            case $REPLY in
            1) 
                break 3
                ;;
            *)  
                if [[ ${REPLY} -gt $(( ${#shaders[@]} + 1 )) ]]; then
                    echo "Unknown shader: [${REPLY}]. Choose again..."
                    break
                fi
                REPLY=$((${REPLY} - 2))
                menu_overlay "${shaders[${REPLY}]}"
                #menu_install_preset "${shaders[${REPLY}]}"
                break
                ;;
            esac
        done
    done
}

function menu_resources() {
    while :
    do
       echo ""
       echo "-= Resources Menu =-"
       PS3="Choose: "
       select option1 in "Install Resources" "Uninstall Resources" "<- Back"
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

function menu_install_preset_arcade() {
    local preset=$1
    
    while : 
    do
        echo ""
        echo "-= Install Arcade Preset =-"
        echo "Selected Arcade Preset: ${preset}"    

        local descr_file="presets-arcade/${preset}.txt"
        [[ -f "$descr_file" ]] && printf "Description: \n$(cat "${descr_file}")\n\n"

        PS3="Choose target system: "
        select option1 in "<- Back" ${SYSTEMS_ARCADE[@]}
        do
            case $REPLY in
            1) 
                break 2
                ;;
            *) # always allow for the unexpected
                REPLY=$((${REPLY} - 2))
                install_preset_arcade "${preset}" "${SYSTEMS_ARCADE[${REPLY}]}"
                break
                ;;
            esac
        done
    done
}

function menu_uninstall_preset_arcade() {

    while : 
    do
        echo ""
        echo "-= Uninstall Arcade Preset =-"
        echo "You are going to install all cfg-files from the following ROM directory!!!"
        PS3="Choose target system: "
        select option1 in "<- Back" ${SYSTEMS_ARCADE[@]}
        do
            case $REPLY in
            1) 
                break 3
                ;;
            *) # always allow for the unexpected
                if [[ ${REPLY} -gt $(( ${#SYSTEMS_ARCADE[@]} + 1 )) ]]; then
                    echo "Unknown preset: [${REPLY}]. Choose again..."
                    break
                fi
                REPLY=$((${REPLY} - 2))
                local sys=${SYSTEMS_ARCADE[${REPLY}]}
                echo "Deleting all cfg files from directory: ${RP_ROMS_DIR}/${sys}"
                rm "${RP_ROMS_DIR}/${sys}"/*.cfg
                break 3
                ;;
            esac
        done
    done
}

function menu_presets_arcade() {
    local presets=($(get_presets_arcade))
    while : 
    do
        echo ""
        echo "-= Arcade Presets Menu =-"
        echo "Arcade preset are per-ROM presets. The following sets are available"
        PS3="Choose preset to install: "
        select option1 in "<- Back" "Uninstall Preset" ${presets[@]}
        do
            case $REPLY in
            1) 
                break 3
                ;;
            2) 
                if [[ ${REPLY} -gt $(( ${#presets[@]} + 2 )) ]]; then
                    echo "Unknown preset: [${REPLY}]. Choose again..."
                    break
                fi
                menu_uninstall_preset_arcade
                ;;
            *)  
                if [[ ${REPLY} -gt $(( ${#presets[@]} + 2 )) ]]; then
                    echo "Unknown preset: [${REPLY}]. Choose again..."
                    break
                fi
                REPLY=$((${REPLY} - 3))
                menu_install_preset_arcade "${presets[${REPLY}]}"
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

    select option in Resources "Configure System(s)"  "Arcade ROM Configs" Quit
    do
        case $REPLY in
            1) 
                menu_resources
                ;;
            2)  
                menu_shaders
                ;;
            3) 
                menu_presets_arcade
                ;;
            4) 
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
