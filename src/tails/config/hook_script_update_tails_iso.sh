#!/bin/bash
# ----------------------------------------------------------------------------------
# Filename:     hook_script_update_tails_iso.sh
# Description:  This script is a Proxmox hook-script
# Require:      Requires 'background_update_tails_iso.sh' bash script 
# ----------------------------------------------------------------------------------

#---- Body -------------------------------------------------------------------------
echo "hook parameters: $1 $2 [$0]"

#---- Set Args
VMID=$1
EVENT=$2

#---- Run the update only on post-start event
if [ "$EVENT" == "post-stop" ]; then
  nohup /var/lib/vz/snippets/background_update_tails_iso.sh "$VMID" &>/dev/null &
  sleep 5s
fi
#-----------------------------------------------------------------------------------
