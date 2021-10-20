#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     update-pihole.sh
# Description:  Source script for PiHole SW and Add-on updater
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------

# Check for Internet connectivity
if nc -zw1 google.com 443; then
  echo
else
  echo "Checking for internet connectivity..."
  echo -e "Internet connectivity status: \033[0;31mDown\033[0m\n\nCannot proceed without a internet connection.\nFix your PVE hosts internet connection and try again..."
  echo
  exit 0
fi

#---- Static Variables -------------------------------------------------------------

#---- Repo variables
# Git server
GIT_SERVER='https://github.com'
# Git user
GIT_USER='ahuacate'
# Git repository
GIT_REPO='pve-homelab'
# Git branch
GIT_BRANCH='master'
# Git common
GIT_COMMON='0'

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------


# Check for PiHole Updatelists script updates
if [ -f /usr/local/sbin/pihole-updatelists ];then
  sudo pihole-updatelists --update --git-branch=master
fi


# Update PiHole SW
PIHOLE_UPDATE="$(sudo pihole -up --check-only)"
if ! grep -q 'Everything is up to date' <<< "${PIHOLE_UPDATE}" ; then
  sudo pihole -up
  if [[ $? -eq 0 ]] ; then
    echo "$(date "+%h %d %T") update: success" >> /var/log/pihole.log
    # Patch for Updatelists script
    sudo sed -e '/pihole updateGravity/ s/^#*/#/' -i /etc/cron.d/pihole
    reboot
  fi
else
    echo "$(date "+%h %d %T") update: nothing to do" >> /var/log/pihole.log
fi