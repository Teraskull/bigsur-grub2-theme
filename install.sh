#!/bin/bash

ROOT_UID=0
THEME_DIR="/usr/share/grub/themes"
THEME_NAME="bigsur"


# Colors
CDEF="\033[0m"          # Default color
CCIN="\033[0;36m"       # Info color
CGSC="\033[0;32m"       # Success color
CRER="\033[0;31m"       # Error color
CWAR="\033[0;33m"       # Warning color
b_CDEF="\033[1;37m"     # Bold default color
b_CCIN="\033[1;36m"     # Bold info color
b_CGSC="\033[1;32m"     # Bold success color
b_CRER="\033[1;31m"     # Bold error color
b_CWAR="\033[1;33m"     # Bold warning color


# Print message with flag type to change message color
prompt() {
    case ${1} in
        "-s"|"--success")
        echo -e "${b_CGSC}${@/-s/}${CDEF}";;  # Print success message
        "-e"|"--error")
        echo -e "${b_CRER}${@/-e/}${CDEF}";;  # Print error message
        "-w"|"--warning")
        echo -e "${b_CWAR}${@/-w/}${CDEF}";;  # Print warning message
        "-i"|"--info")
        echo -e "${b_CCIN}${@/-i/}${CDEF}";;  # Print info message
        *)
        echo -e "$@"
        ;;
    esac
}


# Welcome message
echo ""
prompt -s "\t          *****************************"
prompt -s "\t          *  BigSur Bootloader Theme  *"
prompt -s "\t          *****************************"
prompt -s "\t             Grub theme by Teraskull"
echo ""


# Check command availability
function has_command() {
    command -v $1 > /dev/null
}


# Wait before installing
total=10
count=0
while [ ${count} -lt ${total} ]; do
    tlimit=$(( $total - $count ))
    prompt -i "\rPress Enter to install ${b_CWAR}${THEME_NAME}${b_CCIN} theme (automatically install in ${b_CWAR}${tlimit}${b_CCIN}s): \c"
    read -n 1 -s -t 1 && { break ; }
    count=$((count+1))
done


# Check for root access
prompt -w "\n\nChecking for root access..."
if [ "$UID" -eq "$ROOT_UID" ]; then
    # Create themes directory if does not exist
    prompt -i "\nChecking if ${b_CWAR}${THEME_DIR}${b_CCIN} exists..."
    [[ -d ${THEME_DIR}/${THEME_NAME} ]] && rm -rf ${THEME_DIR}/${THEME_NAME}
    mkdir -p "${THEME_DIR}/${THEME_NAME}"

    prompt -i "\nChecking if ${b_CWAR}${THEME_NAME}${b_CCIN} theme exists..."
    if [ -d ${THEME_NAME} ]; then
        prompt -i "\nInstalling ${b_CWAR}${THEME_NAME}${b_CCIN} theme..."

        # Copy theme
        cp -a ${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}

        # Backup Grub config
        prompt -i "\nBacking up Grub config (${b_CWAR}/etc/default/grub.bak${b_CCIN})..."
        cp -an /etc/default/grub /etc/default/grub.bak

        # Set theme
        prompt -i "\nSetting ${b_CWAR}${THEME_NAME}${b_CCIN} theme as default..."

        grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub

        echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub


        # Update Grub config
        prompt -i "\nUpdating Grub config..."
        if has_command update-grub; then
            update-grub
        elif has_command grub-mkconfig; then
            grub-mkconfig -o /boot/grub/grub.cfg
        elif has_command grub2-mkconfig; then
            if has_command zypper; then
            grub2-mkconfig -o /boot/grub2/grub.cfg
            elif has_command dnf; then
            grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
            fi
        else
            prompt -e "\nError: Cannot update Grub Config. Theme not installed.\n"
        fi

        if [ $? -eq 0 ]; then
            # Success message
            echo ""
            prompt -s "\t          ****************************"
            prompt -s "\t          *  Successfully installed  *"
            prompt -s "\t          ****************************"
            echo ""
        else
            # Error if could not update Grub config
            prompt -e "\nError: Cannot update Grub Config. Theme not installed.\n"
        fi

    else
        # Error if theme folder does not exist on the same level as install.sh
        prompt -e "\nError: Directory ${THEME_NAME} does not exist.\n"
    fi


else
    # Error if script was not run as root
    prompt -e "\nError: Please run script as root.\n"
fi
