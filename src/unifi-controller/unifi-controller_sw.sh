#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     unifi_sw.sh
# Description:  Source script for CT SW
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

# Update these variables as required for your specific instance
app="${REPO_PKG_NAME,,}"       # App name
app_uid=${APP_USERNAME}        # App UID
app_guid=${APP_GRPNAME}        # App GUID

#---- Other Variables --------------------------------------------------------------

#---- Firewall variables
# SSH port
SSH_PORT=22
# Local network
LOCAL_NET=$(hostname -I | awk -F'.' -v OFS="." '{ print $1,$2,"0.0/24" }')

#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Update locales
sudo locale-gen en_US.UTF-8

# Install prerequisites
apt-get install ca-certificates wget -y

#---- Configure firewall
sudo ufw allow ${SSH_PORT}
sudo ufw allow from ${LOCAL_NET} to any port ${SSH_PORT}
sudo ufw allow 8443 # UniFi Controller management port
sudo ufw allow from ${LOCAL_NET} to any port 8443
# UniFi STun & inform port
sudo ufw allow 3478/udp
sudo ufw allow 8080
# Guest portal
sudo ufw allow 8880
sudo ufw allow 8843
# Optional additional ports
sudo ufw allow 5514/udp # Port used for remote syslog capture.
sudo ufw allow 6789 # Port used for UniFi mobile speed test.
sudo ufw allow 27117 # Port used for local-bound database communication.
sudo ufw allow 5656-5699/udp # Ports used by AP-EDU broadcasting.
sudo ufw allow 10001/udp # Port used for device discovery.
sudo ufw allow 1900/udp # Port used for "Make application discoverable on L2 network" in the UniFi Network settings.
# Enable ufw
sudo ufw enable


#---- Install fail2ban
# Install fail2ban
apt-get install fail2ban -y

# Configure fail2ban
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 8h
ignoreip = 127.0.0.1/8 ${LOCAL_NET}
ignoreself = true

[sshd]
enabled = true
EOF

# Restart fail2ban
sudo service fail2ban restart

#---- Install UniFi Controller

# Download GlennR install script
rm unifi-latest.sh &> /dev/null; wget https://get.glennr.nl/unifi/install/install_latest/unifi-latest.sh && bash unifi-latest.sh --skip --skip-swap --add-repository --local-controller
#-----------------------------------------------------------------------------------