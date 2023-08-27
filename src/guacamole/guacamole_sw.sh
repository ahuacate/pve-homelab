#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     guacamole_sw.sh
# Description:  Source script for CT SW
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )
COMMON="$DIR/../../common"
SHARED="$DIR/../../shared"

#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

# Update these variables as required for your specific instance
app="${REPO_PKG_NAME,,}"  # App name
app_uid="$APP_USERNAME"   # App UID
app_guid="$APP_GRPNAME"   # App GUID
user_pwd="$USER_PWD"      # MySQL password
mfa="$MFA"                # Two-factor authentication (TOTP, Duo or none)

#---- Other Variables --------------------------------------------------------------

# Guacamole latest version
GUAC_VERSION="${GUAC_VERSION:-1.5.1}"

#---- Firewall variables
# Guacamole port
GUAC_PORT=8080
# SSH port
SSH_PORT=22
# Local network
LOCAL_NET=$(hostname -I | awk -F'.' -v OFS="." '{ print $1,$2,"0.0/24" }')

#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Run Bash Header
source $COMMON/bash/src/basic_bash_utility.sh

# Update locales
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
sudo locale-gen en_US.UTF-8

# Update Ubuntu
apt-get update -y
apt-get upgrade -y

# Install Crudini
apt-get install crudini -y

# Add Packages
apt-get install software-properties-common -y
add-apt-repository -y universe
apt-get update -y


#---- Install Guacamole SW

# Download upgrade script
wget -q --show-progress -O guac-install.sh https://raw.githubusercontent.com/MysticRyuujin/guac-install/main/guac-install.sh
if [ $? -ne 0 ]
then
  echo -e "WARNING:${NC}\nFailed to download: ${WHITE}guac-install.sh${NC}"
  echo
  return
fi
# Set script permissions
chmod +x guac-install.sh

# Run installer
./guac-install.sh --mysqlpwd ${user_pwd} --guacpwd ${user_pwd} --${mfa} --installmysql 2> /dev/null

# Allow ports
sudo ufw allow $GUAC_PORT/tcp
sudo ufw allow $SSH_PORT
# Enable ufw
sudo ufw enable
sudo ufw reload

# Run guacamole tune
source $DIR/config/guacamole_tuneup.sh


#---- Install fail2ban

# Install fail2ban
apt-get install fail2ban -y

# Configure fail2ban default
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 8h
maxretry = 5
ignoreip = 127.0.0.1/8 ${LOCAL_NET}
ignoreself = true

[sshd]
enabled = true
EOF

cat <<EOF > /etc/fail2ban/jail.d/guacamole-auth.conf
[guacamole-auth]
enabled = true
port = http,https,80,443
filter = guacamole
EOF

cat <<EOF > /etc/fail2ban/filter.d/guacamole-auth.conf
[Definition]
failregex = \bAuthentication attempt from \[<HOST>(?:,.*)?\] for user ".*" failed\.
ignoreregex =
EOF

# Start fail2ban
systemctl enable fail2ban.service
pct_start_systemctl "fail2ban.service"
#-----------------------------------------------------------------------------------