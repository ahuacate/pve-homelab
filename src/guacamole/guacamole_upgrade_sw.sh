#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     guacamole_upgrade_sw.sh
# Description:  Source script for CT SW
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

#---- Terminal settings
RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[0;32m'
WHITE=$'\033[1;37m'
NC=$'\033[0m'
UNDERLINE=$'\033[4m'
printf '\033[8;40;120t'

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Update CT
apt-get update -y 
apt-get upgrade -y

# Download upgrade script
wget  -q --show-progress -O guac-upgrade.sh https://raw.githubusercontent.com/MysticRyuujin/guac-install/master/guac-upgrade.sh
if [ $? -ne 0 ]; then
  echo -e "${RED}WARNING:${NC}\nFailed to download: ${WHITE}guac-upgrade.sh${NC}"
  echo
  return
fi
chmod +x guac-upgrade.sh

#---- Install Guacamole upgrade
# Run updater script
./guac-upgrade.sh

# Clean up
rm -f "guac-upgrade.sh"

#-----------------------------------------------------------------------------------