#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     guacamole_sw.sh
# Description:  Source script for CT SW
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
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
GUAC_VERSION="${GUAC_VERSION:-1.4.0}"

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

# Download upgrade script
wget -q --show-progress -O guac-install.sh https://raw.githubusercontent.com/MysticRyuujin/guac-install/master/guac-install.sh
if [ $? -ne 0 ]
then
  echo -e "${RED}WARNING:${NC}\nFailed to download: ${WHITE}guac-install.sh${NC}"
  echo
  return
fi
# Set permissions
chmod +x guac-install.sh

#---- Install Guacamole
./guac-install.sh --mysqlpwd ${user_pwd} --guacpwd ${user_pwd} --installmysql --${mfa}

#---- Configure firewall
sudo ufw allow $GUAC_PORT/tcp
sudo ufw allow $SSH_PORT
# Enable ufw
sudo ufw enable
sudo ufw reload


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

# Restart fail2ban
sudo service fail2ban restart
#-----------------------------------------------------------------------------------