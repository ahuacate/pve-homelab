#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     guacamole_upgrade_sw.sh
# Description:  Source script for CT SW
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )
COMMON="$DIR/../../../common"
SHARED="$DIR/../../../shared"

#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------
#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Run Bash Header
source $COMMON/bash/src/basic_bash_utility.sh

# Update CT
apt-get update -y 
apt-get upgrade -y

# Download upgrade script
wget  -q --show-progress -O guac-upgrade.sh https://raw.githubusercontent.com/MysticRyuujin/guac-install/main/guac-upgrade.sh
if [ $? -ne 0 ]
then
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