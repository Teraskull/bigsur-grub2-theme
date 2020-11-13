#!/bin/bash

THEME='bigsur'

# Pre-authorise sudo
sudo echo
# Detect distro and set GRUB location and update method
GRUB_DIR='grub'
UPDATE_GRUB=''


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


# Check if theme directory exists before proceeding with installation
[ ! -d ${THEME} ] && prompt -e "\nError: Directory ${b_CWAR}${THEME}${b_CRER} does not exist.\n" && exit 1


# Welcome message
echo ""
prompt -s "\t          *****************************"
prompt -s "\t          *  BigSur Bootloader Theme  *"
prompt -s "\t          *****************************"
prompt -s "\t             Grub theme by Teraskull"
echo ""


# Wait before installing
total=10
count=0
while [ ${count} -lt ${total} ]; do
    tlimit=$(( $total - $count ))
    prompt -i "\rPress Enter to install ${b_CWAR}${THEME}${b_CCIN} theme (automatically install in ${b_CWAR}${tlimit}${b_CCIN}s): \c"
    read -n 1 -s -t 1 && { break ; }
    count=$((count+1))
done


if [ -e /etc/os-release ]; then

    source /etc/os-release

    if [[ "$ID" =~ (debian|ubuntu|solus) || \
          "$ID_LIKE" =~ (debian|ubuntu) ]]; then

        UPDATE_GRUB='update-grub'

    elif [[ "$ID" =~ (arch|manjaro|gentoo) || \
            "$ID_LIKE" =~ (archlinux|manjaro|gentoo) ]]; then

        UPDATE_GRUB='grub-mkconfig -o /boot/grub/grub.cfg'

    elif [[ "$ID" =~ (centos|fedora|opensuse) || \
            "$ID_LIKE" =~ (fedora|rhel|suse) ]]; then

        GRUB_CFG_PATH='/boot/grub2/grub.cfg'

        if [ -d /boot/efi/EFI/${ID} ]
        then
            GRUB_CFG_PATH="/boot/efi/EFI/${ID}/grub.cfg"
        fi

        # BLS etries have 'kernel' class, copy corresponding icon
        if [[ -d /boot/loader/entries && -e icons/${ID}.png ]]
        then
            cp icons/${ID}.png icons/kernel.png
        fi

        GRUB_DIR='grub2'
        UPDATE_GRUB="grub2-mkconfig -o ${GRUB_CFG_PATH}"
    fi
fi

prompt -i "\n\nRemoving previous version of ${b_CWAR}${THEME}${b_CCIN} theme if exists"
sudo rm -r /boot/${GRUB_DIR}/themes/${THEME}

prompt -i "\nCreating ${b_CWAR}${THEME}${b_CCIN} theme directory under /boot/${GRUB_DIR}/themes/"
sudo mkdir -p /boot/${GRUB_DIR}/themes/${THEME}

prompt -i "\nCopying ${b_CWAR}${THEME}${b_CCIN} theme to previously created directory"
sudo cp -r ${THEME}/* /boot/${GRUB_DIR}/themes/${THEME}

prompt -i "\nRemoving other themes from GRUB config"
sudo sed -i '/^GRUB_THEME=/d' /etc/default/grub

prompt -i "\nEnsuring that GRUB uses graphical output"
sudo sed -i 's/^\(GRUB_TERMINAL\w*=.*\)/#\1/' /etc/default/grub

prompt -i "\nRemoving empty lines at the end of GRUB config"  # optional
sudo sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' /etc/default/grub

prompt -i "\nAdding new line to GRUB config"  # optional
echo | sudo tee -a /etc/default/grub

prompt -i "\nAdding ${b_CWAR}${THEME}${b_CCIN} theme to GRUB config"
echo "GRUB_THEME=\"/boot/${GRUB_DIR}/themes/${THEME}/theme.txt\"" | sudo tee -a /etc/default/grub

prompt -i "\nUpdating GRUB"
if [[ $UPDATE_GRUB ]]; then
    eval sudo "$UPDATE_GRUB"

    echo ""
    prompt -s "\t          ****************************"
    prompt -s "\t          *  Successfully installed  *"
    prompt -s "\t          ****************************"

else
    prompt -e   ---------------------------------------------------------------------------------------
    prompt -e    Cannot detect your distro, you will need to run \`grub-mkconfig\` as root manually.
    prompt -e
    prompt -e    Common ways:
    prompt -e    "- Debian, Ubuntu, Solus and derivatives: \`update-grub\` or \`grub-mkconfig -o /boot/grub/grub.cfg\`"
    prompt -e    "- RHEL, CentOS, Fedora, SUSE and derivatives: \`grub2-mkconfig -o /boot/grub2/grub.cfg\`"
    prompt -e    "- Arch, Gentoo and derivatives: \`grub-mkconfig -o /boot/grub/grub.cfg\`"
    prompt -e    ---------------------------------------------------------------------------------------
fi
