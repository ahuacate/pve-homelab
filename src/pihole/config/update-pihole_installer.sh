#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     update-pihole_installer.sh
# Description:  Installer for PiHole SW and Add-on updater
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------
#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

# Push updater script to CT
pct push $CTID ${SRC_DIR}/pihole/config/update-pihole.sh /usr/local/sbin/update-pihole.sh
pct exec $CTID -- bash -c 'sudo chmod a+x /usr/local/sbin/update-pihole.sh'

# Create a systemd service for the updater
cat << 'EOF' > ${DIR}/update-pihole.service 
[Unit]
Description=Update pihole
After=network-online.target
  
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/update-pihole.sh
EOF
pct push $CTID ${DIR}/update-pihole.service /etc/systemd/system/update-pihole.service

# Create a systemd timer
# Default time is Monday 03:00
cat << 'EOF' > ${DIR}/update-pihole.timer 
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
pct push $CTID ${DIR}/update-pihole.timer /etc/systemd/system/update-pihole.timer

# Enable systemd timer
pct exec $CTID -- bash -c 'sudo systemctl --quiet daemon-reload'
pct exec $CTID -- bash -c 'sudo systemctl --quiet enable --now update-pihole.timer'

#---- Finish Line ------------------------------------------------------------------