#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     unifi_controller_backup.sh
# Description:  Backup script for UniFi Controller settings to NAS
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

# Update these variables as required for your specific instance
app=''
app_uid=''
app_guid=''

# Define the number of days
days_to_keep=30

# Define the NAS directory path
nas_backup_dir="/mnt/backup/$app/autobackup"

# Calculate the timestamp for files older than x days
timestamp=$(date -d "$days_to_keep days ago" +%s)

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Check if user exists
if ! id -u "$app_uid" >/dev/null 2>&1; then
  exit 1
fi

# Check rw permissions
if ! sudo -u $app_uid test -w "/mnt/backup"; then
  exit 1
fi

# Chk for network backup mount
if [ -d /mnt/backup ]
then
  sudo -u $app_uid mkdir -p $nas_backup_dir
  sudo -u $app_uid mkdir -p /mnt/backup/$app/manualbackup
else
  exit 1
fi

# Chk for default user 'HOME' dir
if [ -d "/home/$app_uid" ]
then
  sudo -u $app_uid mkdir -p /home/$app_uid/unifi_autobackup
  chown $app_uid:$app_guid /home/$app_uid/unifi_autobackup
else
  exit 1
fi

#---- Copy all UniFi backup unf files to default user HOME dir

# Remove default user backup files
rm -f /home/$app_uid/unifi_autobackup/* 2> /dev/null

# Copy UniFi backup files to default user HOME
cp -fR /usr/lib/unifi/data/backup/autobackup/* /home/$app_uid/unifi_autobackup/ 2> /dev/null
chown -R $app_uid:$app_guid /home/$app_uid/unifi_autobackup/


#---- Copy all UniFi backup unf files to NAS

# Remove aged UniFi backup files from NAS
sudo -u $app_uid find "$nas_backup_dir/" -type f -mtime +"$days_to_keep" -exec rm {} \;

# Copy UniFi backup to NAS
sudo -u $app_uid cp -fR /home/$app_uid/unifi_autobackup/* "$nas_backup_dir/" 2> /dev/null
#-----------------------------------------------------------------------------------