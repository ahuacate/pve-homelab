#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     sftpgo_sw.sh
# Description:  Source script for CT SW
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )
COMMON="$DIR/../../common"
SHARED="$DIR/../../shared"

#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

# Update these variables as required for your specific instance
app="${REPO_PKG_NAME,,}"       # App name
app_uid="$APP_USERNAME"        # App UID
app_guid="$APP_GRPNAME"        # App GUID

#---- Other Variables --------------------------------------------------------------

#---- Firewall variables
# SSH port
SSH_PORT=22
# FTP ports
SFTPGO_PORT=2022
FTPGO_PORT=2121
PASSIVE_PORT='50000:50100'
# WebDAV Port
WEBDAV_PORT=10080
# Local network
LOCAL_NET=$(hostname -I | awk -F'.' -v OFS="." '{ print $1,$2,"0.0/16" }')

#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Run update & upgrade
apt-get update && apt-get upgrade -y
apt-get install apt-transport-https -y

# Run Bash Header
source $COMMON/bash/src/basic_bash_utility.sh

# Add Repos
apt install software-properties-common -y
apt update -y
add-apt-repository ppa:sftpgo/sftpgo -y
apt update -y

#---- Install sFTPGo
apt install sftpgo -y



# Create app .service with correct user startup
pct_stop_systemctl "sftpgo.service"
sudo chown -R $app_uid:$app_guid /etc/sftpgo /var/lib/sftpgo
mkdir -p /etc/systemd/system/sftpgo.service.d

sudo tee /etc/systemd/system/sftpgo.service.d/override.conf > /dev/null <<-EOF
[Service]
User=home
Group=homelab
EOF

# Enable FTPd
sudo mkdir -p /etc/sftpgo/env.d
echo "SFTPGO_FTPD__BINDINGS__0__PORT=2121" | sudo tee /etc/sftpgo/env.d/ftpd.env > /dev/null
chown $app_uid:$app_guid /etc/sftpgo/env.d/ftpd.env

# Enable WebDAV
echo "SFTPGO_WEBDAVD__BINDINGS__0__PORT=10080" | sudo tee /etc/sftpgo/env.d/webdavd.env > /dev/null
chown $app_uid:$app_guid /etc/sftpgo/env.d/webdavd.env

# Restart/Reload SFTPGo
systemctl daemon-reload
pct_start_systemctl "sftpgo.service"

#---- Configure firewall
# Restrict access to local network only and HA Proxy
sudo ufw allow from $LOCAL_NET to any port $SSH_PORT
sudo ufw allow from $LOCAL_NET to any port 8080  # Allow HTTP interface
sudo ufw allow from $LOCAL_NET to any port $SFTPGO_PORT  # Allow SFTPGo
sudo ufw allow from $LOCAL_NET to any port $FTPGO_PORT  # Allow FTPGo
sudo ufw allow from $LOCAL_NET to any port $PASSIVE_PORT proto tcp
sudo ufw allow from $LOCAL_NET to any port $WEBDAV_PORT  # Allow WebDAV
sudo ufw default deny incoming
sudo ufw default allow outgoing

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
#-----------------------------------------------------------------------------------