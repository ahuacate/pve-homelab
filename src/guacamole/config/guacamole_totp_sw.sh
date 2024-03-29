#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     guacamole_totp_sw.sh
# Description:  Source script for CT SW
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )
COMMON="$DIR/../../../common"
SHARED="$DIR/../../../shared"

#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------
#---- Other Variables --------------------------------------------------------------

# Guacamole latest version
GUAC_VERSION="${GUAC_VERSION:-1.5.1}"

# Get Tomcat Version
TOMCAT=$(ls /etc/ | grep tomcat)

# Get Current Guacamole Version
VERSION=$(grep -oP 'Guacamole.API_VERSION = "\K[0-9\.]+' /var/lib/${TOMCAT}/webapps/guacamole/guacamole-common-js/modules/Version.js)
GUAC_VERSION="${GUAC_VERSION:-${VERSION}}"

# Set SERVER to be the preferred download server from the Apache CDN
SERVER="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VERSION}"

#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Run Bash Header
source $COMMON/bash/src/basic_bash_utility.sh

# Check for TOTP extensions and upgrade if found
for file in /etc/guacamole/extensions/guacamole-auth-totp*.jar
do
  if [[ -f $file ]]
  then
    echo -e "${RED}WARNING:${NC}\nTOTP extension is already installed. Skipping this installation..."
    echo
    return
  fi
done

#---- Install Guacamole extension

# Download Guacamole extension
wget -q --show-progress -O guacamole-auth-totp-${GUAC_VERSION}.tar.gz ${SERVER}/binary/guacamole-auth-totp-${GUAC_VERSION}.tar.gz
if [ $? -ne 0 ]
then
    echo -e "${RED}WARNING:${NC}\nFailed to download: ${WHITE}guacamole-auth-totp-${GUAC_VERSION}.tar.gz${NC}"
    echo
    return
fi

# Stop services
pct_stop_systemctl "$TOMCAT"
pct_stop_systemctl "guacd"

# Install
tar -xzf guacamole-auth-totp-${GUAC_VERSION}.tar.gz
cp guacamole-auth-totp-${GUAC_VERSION}/guacamole-auth-totp-${GUAC_VERSION}.jar /etc/guacamole/extensions/
echo -e "TOTP extension status: ${YELLOW}installed${NC}"

# Clean up
rm -rf "guacamole-auth-totp-${GUAC_VERSION}"
rm -f "guacamole-auth-totp-${GUAC_VERSION}.tar.gz"

# Restart services
pct_start_systemctl "$TOMCAT"
pct_start_systemctl "guacd"
#-----------------------------------------------------------------------------------