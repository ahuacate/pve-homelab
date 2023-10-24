#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_installer.sh
# Description:  Installer script for PVE Homelab
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#---- Source Github
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/main/pve_homelab_installer.sh)"

#---- Source local Git
# /mnt/pve/nas-01-git/ahuacate/pve-homelab/pve_homelab_installer.sh

#---- Installer Vars ---------------------------------------------------------------

# Git server
GIT_SERVER='https://github.com'
# Git user
GIT_USER='ahuacate'
# Git repository
GIT_REPO='pve-homelab'
# Git branch
GIT_BRANCH='main'
# Git common
GIT_COMMON='0'

# Edit this list to set installer products.
# vm_LIST=( "name:build:vm_type:desc" )
# name        ---> name of the main application
# build_model ---> build model/version of the name (i.e omv build version for a nas)
# vm_type     ---> 'vm' or 'ct'
# desc        ---> description of the main application name
# Fields must match GIT_APP_SCRIPT dir and filename:
# i.e .../<build_type>/${GIT_REPO}_<vm_type>_<app_name>_installer.sh '(i.e .../ubuntu/pve_nas_ct_nas_installer.sh')
vm_LIST=( "pihole:pihole:ct:DNS sinkhole with optional dhcp server"
"ddclient:ddclient:ct:dynamic dns updater"
"guacamole:guacamole:ct:clientless remote desktop gateway"
"guacardp:guacardp:ct:guacamole rdp client"
"tailscale:tailscale:ct:Zero config VPN service for remote access"
"unifi-controller:unifi-controller:ct:unifi controller" )

#-----------------------------------------------------------------------------------
# NO NOT EDIT HERE DOWN
#---- Dependencies -----------------------------------------------------------------

#---- Check for Internet connectivity

# List of well-known websites to test connectivity (in case one is blocked)
websites=( "google.com 443" "github.com 443" "cloudflare.com 443" "apple.com 443" "amazon.com 443" )
# Loop through each website in the list
for website in "${websites[@]}"
do
  # Test internet connectivity
  nc -zw1 $website > /dev/null 2>&1
  # Check the exit status of the ping command
  if [ $? = 0 ]
  then
    # Flag to track if internet connection is up
    connection_up=0
    break
  else
  # Flag to track if internet connection is down
  connection_up=1
  fi
done
# On connection fail
if [ "$connection_up" = 1 ]
then
  echo "Checking for internet connectivity..."
  echo -e "Internet connectivity status: \033[0;31mDown\033[0m\n\nCannot proceed without a internet connection.\nFix your PVE hosts internet connection and try again..."
  echo
  exit 0
fi

#---- Static Variables -------------------------------------------------------------

#---- Set Package Installer Temp Folder

# Set 'rep_temp' dir
REPO_TEMP='/tmp'
# Change to 'repo temp' dir
cd $REPO_TEMP

#---- Local Repo path (check if local)

# For local SRC a 'developer_settings.git' file must exist in repo dir
REPO_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P | sed "s/${GIT_USER}.*/$GIT_USER/" )"

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------

#---- Package loader

# Check for local source
if [ -f "$REPO_PATH/common/bash/src/pve_repo_loader.sh" ] && [ "$(sed -n 's/^dev_git_mount=//p' $REPO_PATH/developer_settings.git 2> /dev/null)" = 0 ]
then
  # Download Local loader (developer)
  source $REPO_PATH/common/bash/src/pve_repo_loader.sh
else
  # Download Github loader
  wget -qL - https://raw.githubusercontent.com/$GIT_USER/common/main/bash/src/pve_repo_loader.sh -O $REPO_TEMP/pve_repo_loader.sh
  chmod +x "$REPO_TEMP/pve_repo_loader.sh"
  source $REPO_TEMP/pve_repo_loader.sh
fi

#---- Body -------------------------------------------------------------------------

#---- Run Installer

# Run repo installer (repo product selector)
source $REPO_PATH/$GIT_REPO/common/bash/src/pve_repo_installer_main.sh
#-----------------------------------------------------------------------------------