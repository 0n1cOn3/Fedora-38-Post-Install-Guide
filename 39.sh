#!/usr/bin/env bash
# From the Guide from https://github.com/0n1cOn3/Fedora-38-Post-Install-Guide/tree/main
# Script written by 0n1cOn3/h@x 2023
####################################

# Check if the script is run as root
if [ "$(id -u)" -eq 0 ]; then
    echo "+++++++++++++++++++++++++"
    echo "39.sh is running as root."
    echo "+++++++++++++++++++++++++"
    echo ""
    sleep 2
else
    echo "39.sh is not running as root. Please run with 'sudo bash 39.sh.'"
    exit 1
fi

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Path to the dnf.conf file
dnf_conf="/etc/dnf/dnf.conf"

# Default configuration options
fastestmirror_option="fastestmirror=1"
max_parallel_downloads_option="max_parallel_downloads=10"
deltarpm_option="deltarpm=true"

# Check if the file already exists, otherwise create it
if [ ! -f "$dnf_conf" ]; then
    touch "$dnf_conf"
fi

# Initialize variables to track changes for each option
fastestmirror_change=false
max_parallel_downloads_change=false
deltarpm_change=false

# Check and display note for fastestmirror_option
if ! grep -q "^$fastestmirror_option" "$dnf_conf"; then
    echo -e "${YELLOW}NEW:${NC} Pending changes!"
    echo -e "${YELLOW}Note:${NC} The fastestmirror=1 plugin can be counterproductive at times. 
Set it to fastestmirror=0 if you are facing bad download speeds. 
Many users have reported better download speeds with the plugin enabled,
so it is there by default."
 echo ""
 sleep 5
    fastestmirror_change=true
fi

# Check and display message for max_parallel_downloads_option
if ! grep -q "^$max_parallel_downloads_option" "$dnf_conf"; then
    echo -e "${YELLOW}NEW:${NC} Pending changes!"
    echo -e "${RED}max_parallel_downloads${NC} needs to be configured."
    echo ""
    max_parallel_downloads_change=true
fi

# Check and display message for deltarpm_option
if ! grep -q "^$deltarpm_option" "$dnf_conf"; then
    echo -e "${YELLOW}NEW:${NC} Pending changes!"
    echo -e "${RED}deltarpm${NC} needs to be configured."
    echo ""
    deltarpm_change=true
fi

# Prompt user to apply changes if necessary
if [ "$fastestmirror_change" = true ] || [ "$max_parallel_downloads_change" = true ] || [ "$deltarpm_change" = true ]; then
    read -p "Do you want to apply the changes? (y/n): " choice
    if [ "$choice" == "y" ]; then
        # Apply changes only for the options that are not present
        $fastestmirror_change && echo "$fastestmirror_option" >> "$dnf_conf"
        $max_parallel_downloads_change && echo "$max_parallel_downloads_option" >> "$dnf_conf"
        $deltarpm_change && echo "$deltarpm_option" >> "$dnf_conf"
        echo -e "${GREEN}Changes applied successfully.${NC}"
    else
        echo -e "${RED}Changes not applied.${NC}"
    fi
else
    echo -e "${GREEN}Configuration is already up to date.${NC}"
fi
# close function

# New function here
# Enable RPM Fusion repositories and update app-stream metadata
echo -e "\nEnabling RPM Fusion repositories and updating app-stream metadata..."
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf groupupdate core
echo -e "${GREEN}RPM Fusion repositories enabled and app-stream metadata updated.${NC}"
# close function
echo -e "Applying latest updates. This can may take some time. D: . :D ."
sudo dnf -y update
sudo dnf -y upgrade --refresh
# reboot here function

# new function
# Checking for firmware updates and patches.
sudo fwupdmgr get-devices 
sudo fwupdmgr refresh --force 
sudo fwupdmgr get-updates 
sudo fwupdmgr update

# add function where the user gets asked if he uses this script with lap or not.
# If not, skip this.

sudo dnf install tlp tlp-rdw
sudo systemctl mask power-profiles-daemon
sudo dnf install powertop
sudo powertop --auto-tune
# close function

# here new function
# Installing MM-Codecs for proper playback.
sudo dnf groupupdate 'core' 'multimedia' 'sound-and-video' --setop='install_weak_deps=False' --exclude='PackageKit-gstreamer-plugin' --allowerasing && sync
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
sudo dnf install lame\* --exclude=lame-devel
sudo dnf group upgrade --with-optional Multimedia

# H/W Video Decoding with VA-API
sudo dnf install ffmpeg ffmpeg-libs libva libva-utils
read -p "Intel or AMD ?: " choice
if [ "$choice" == "Intel" -o "$choice" == "intel" ]; then
    sudo dnf install intel-media-driver
	elif [ "$choice" == "AMD" -o "$choice" == "amd" ]; then
    sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
	else
    echo -e "${GREEN}No Intel/AMD changes applied. Continuing!${NC}"
fi

# Enabling OpenH264 for Firefox
sudo dnf config-manager --set-enabled fedora-cisco-openh264
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
echo "$GREEN Note:$NC Enable the OpenH264 Plugin in Firefox's settings"
sleep 2
# function closed

# new function here // System Tweakings
# Modern Standy
sudo grubby --update-kernel=ALL --args="mem_sleep_default=s2idle"
echo -e "If "s2idle" doesn't work for you i.e. people with
alder lake CPUs, then you might want to refer to this:
https://www.reddit.com/r/linuxhardware/comments/ng166t/s3_deep_sleep_not_working/"

# Disable NWM-Wait Online service
echo -e "Disabling it can decrease the boot time by at least ~15s-20s"
sudo systemctl disable NetworkManager-wait-online.service
