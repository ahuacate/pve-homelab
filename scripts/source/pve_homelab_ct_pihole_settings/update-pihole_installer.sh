#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     update-pihole_installer.sh
# Description:  Installer for PiHole SW and Add-on updater
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------

# Check for Internet connectivity
if nc -zw1 google.com 443; then
  echo
else
  echo "Checking for internet connectivity..."
  echo -e "Internet connectivity status: \033[0;31mDown\033[0m\n\nCannot proceed without a internet connection.\nFix your PVE hosts internet connection and try again..."
  echo
  exit 0
fi

#---- Static Variables -------------------------------------------------------------

#---- Repo variables
# Git server
GIT_SERVER='https://github.com'
# Git user
GIT_USER='ahuacate'
# Git repository
GIT_REPO='pve-homelab'
# Git branch
GIT_BRANCH='master'
# Git common
GIT_COMMON='0'

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

# Push updater script to CT
pct push $CTID ${DIR}/source/pve_homelab_ct_pihole_settings/update-pihole.sh /usr/local/sbin/update-pihole.sh
pct exec $CTID -- bash -c 'sudo chmod a+x /usr/local/sbin/update-pihole.sh'

# Create a systemd service for the updater
cat << 'EOF' > ${TEMP_DIR}/update-pihole.service 
[Unit]
Description=Update pihole
After=network-online.target
  
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/update-pihole.sh
EOF
pct push $CTID ${TEMP_DIR}/update-pihole.service /etc/systemd/system/update-pihole.service

# Create a systemd timer
# Default time is Monday 03:00
cat << 'EOF' > ${TEMP_DIR}/update-pihole.timer 
[Unit]
Description=Timer for updating pihole
Wants=network-online.target
  
[Timer]
OnBootSec=
OnCalendar=Mon *-*-* 03:00:00
Persistent=true
 
[Install]
WantedBy=timers.target
EOF
pct push $CTID ${TEMP_DIR}/update-pihole.timer /etc/systemd/system/update-pihole.timer

# Enable systemd timer
pct exec $CTID -- bash -c 'sudo systemctl --quiet daemon-reload'
pct exec $CTID -- bash -c 'sudo systemctl --quiet enable --now update-pihole.timer'

#---- Finish Line ------------------------------------------------------------------