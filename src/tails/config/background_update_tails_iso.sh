#!/bin/bash
# ----------------------------------------------------------------------------------
# Filename:     background_update_tails_iso.sh
# Description:  This script is for updating Tails after shutdown
# Require:      Requires Proxmox hook-script
# Notes:        Script is run by a nohup parent hook-script
# ----------------------------------------------------------------------------------

#---- Functions --------------------------------------------------------------------

# Function to update VM configuration and handle lock retries
update_vm_config() {
  local retries=5
  local delay=10
  local attempt=0

  # Gracefully stop the VM
  if qm status "$VMID" | grep -q "status: running"; then
    qm stop "$VMID"
  fi

  # If the VM is still running, force stop it
  if qm status "$VMID" | grep -q "status: running"; then
    echo "Graceful stop failed. Forcing stop."
    PID=$(ps aux | grep "kvm" | grep "\-id $VMID" | awk '{print $2}')
    kill -9 "$PID"
    sleep 5  # Give some time for the VM to stop
  fi

  # Update VMID config file
  while (( attempt < retries )); do
    if qm set "$VMID" --cdrom "${ISO_STORAGE_PREFIX}:iso/$ISO_FILENAME_LATEST,media=cdrom"; then
      find "$ISO_PATH" -name 'tails-amd64-*.iso' ! -name "$ISO_FILENAME_LATEST" -exec rm -f {} + # Remove old Tails ISO files except the latest one
      return 0
    else
      echo "Failed to update VM configuration. Retrying in $delay seconds..."
      sleep $delay
      (( attempt++ ))
      delay=$(( delay * 2 ))  # Exponential backoff
    fi
  done
}

#---- Body -------------------------------------------------------------------------

#---- Get VM ID from arguments
VMID=$1
if [ -z "$VMID" ]; then
  echo "Usage: $0 <VMID>"
  exit 1
fi

#--- Install lynx
if [[ ! $(dpkg -s lynx 2> /dev/null) ]]; then
  apt-get install lynx -y
fi

# Define URL and download path
TAILS_BASE_URL='https://mirrors.edge.kernel.org/tails/stable'
ISO_PATH="/var/lib/vz/template/iso"

# Extract ISO path prefix from VM configuration
ISO_STORAGE_PREFIX=$(qm config "$VMID" | grep -oP "(?<=^ide2: )[a-zA-Z0-9\-]+(?=:iso/)")

# Fetch the latest Tails ISO directory
ISO_DIR_LATEST=$(lynx -dump -listonly "$TAILS_BASE_URL" | grep 'tails-amd64-' | awk '{print $2}' | sort -V | tail -n 1 | xargs basename)
ISO_FILENAME_LATEST="${ISO_DIR_LATEST}.iso"
ISO_URL="${TAILS_BASE_URL}/${ISO_DIR_LATEST}/${ISO_FILENAME_LATEST}"

# Full path of the latest ISO file
ISO_FILEPATH="${ISO_PATH}/${ISO_FILENAME_LATEST}"

# Check if the latest ISO exists and matches the current ISO file
if [ -f "$ISO_FILEPATH" ]; then
  if qm config "$VMID" | grep -q "${ISO_STORAGE_PREFIX}:iso/${ISO_FILENAME_LATEST}"; then
    echo "The ISO file is already up to date. No further action needed."
    exit 0
  fi
fi


#---- Run ISO update after stopping VM
# Tails requires updating

# Check if the latest ISO exists
if [ ! -f "$ISO_FILEPATH" ]; then
  # Download the latest ISO file
  wget -qNLc -T 15 -c "$ISO_URL" -P "$ISO_PATH"
fi

# Update the VM configuration to use the latest ISO file
if update_vm_config; then
  echo "ISO updated successfully."
fi
#-----------------------------------------------------------------------------------