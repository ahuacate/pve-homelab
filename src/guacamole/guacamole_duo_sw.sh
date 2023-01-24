#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     guacamole_duo_sw.sh
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

# Guacamole latest version
GUAC_VERSION="${GUAC_VERSION:-1.4.0}"

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

# Check for Duo extensions and upgrade if found
for file in /etc/guacamole/extensions/guacamole-auth-duo*.jar; do
  if [[ -f $file ]]; then
    echo -e "${RED}WARNING:${NC}\nDuo extension is already installed. Skipping this installation..."
    echo
    return
  fi
done

#---- Install Guacamole extension

# Download Guacamole extension
wget -q --show-progress -O guacamole-auth-duo-${GUAC_VERSION}.tar.gz ${SERVER}/binary/guacamole-auth-duo-${GUAC_VERSION}.tar.gz
if [ $? -ne 0 ]; then
    echo -e "${RED}WARNING:${NC}\nFailed to download: ${WHITE}guacamole-auth-duo-${GUAC_VERSION}.tar.gz${NC}"
    echo
    return
fi

# Stop tomcat and guacamole
service ${TOMCAT} stop
service guacd stop

# Install
tar -xzf guacamole-auth-duo-${GUAC_VERSION}.tar.gz
cp guacamole-auth-duo-${GUAC_VERSION}/guacamole-auth-duo-${GUAC_VERSION}.jar /etc/guacamole/extensions/
echo -e "Duao extension status: ${YELLOW}installed${NC}"

# Clean up
rm -rf "guacamole-auth-duo-${GUAC_VERSION}"
rm -f "guacamole-auth-duo-${GUAC_VERSION}.tar.gz"

# Restart tomcat
service ${TOMCAT} restart
service guacd restart

#-----------------------------------------------------------------------------------