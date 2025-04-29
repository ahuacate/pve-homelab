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
SFTPGO_PORT=2121
# Local network
LOCAL_NET=$(hostname -I | awk -F'.' -v OFS="." '{ print $1,$2,"0.0/24" }')

#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Run update & upgrade
apt-get update && apt-get upgrade -y
apt-get install apt-transport-https -y

# Run Bash Header
source $COMMON/bash/src/basic_bash_utility.sh

#---- Install sFTPGo
add-apt-repository ppa:sftpgo/sftpgo -y
apt update -y
apt install sftpgo -y

# # Create app .service with correct user startup
# cat <<EOF | tee /etc/systemd/system/$app.service >/dev/null
# [Unit]
# Description=Syncthing - BAMF Open Source File Synchronization for %I
# Documentation=man:syncthing(1)
# After=network.target

# [Service]
# User=$app_uid
# ExecStart=/usr/bin/syncthing -no-browser -gui-address="0.0.0.0:8384" -no-restart -logflags=0
# Restart=on-failure
# SuccessExitStatus=3 4
# RestartForceExitStatus=3 4

# [Install]
# WantedBy=multi-user.target
# EOF

# # Systemd enable
# systemctl enable $app.service


#---- Configure firewall
sudo ufw allow $SSH_PORT
sudo ufw allow from $LOCAL_NET to any port $SSH_PORT
# Optional additional ports
sudo ufw allow sftpgo  # Allow Syncthing
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