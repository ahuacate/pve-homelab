#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_pihole.sh
# Description:  This script is for creating a PiHole CT
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/master/scripts/pve_homelab_ct_pihole.sh)"

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
COMMON_PVE_SOURCE="${DIR}/../../common/pve/source"

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

# Run Bash Header
source ${COMMON_PVE_SOURCE}/pvesource_bash_defaults.sh

#---- Static Variables -------------------------------------------------------------

# Set Max CT Host CPU Cores 
HOST_CPU_CORES=$(( $(lscpu | grep -oP '^Socket.*:\s*\K.+') * ($(lscpu | grep -oP '^Core.*:\s*\K.+') * $(lscpu | grep -oP '^Thread.*:\s*\K.+')) ))
if [ ${HOST_CPU_CORES} -gt 4 ]; then 
  CT_CPU_CORES_VAR=$(( ${HOST_CPU_CORES} / 2 ))
elif [ ${HOST_CPU_CORES} -le 4 ]; then
  CT_CPU_CORES_VAR=2
fi

# CT SSH Port
SSH_PORT_VAR='22'

# SSHd Status (0 is enabled, 1 is disabled)
SSH_ENABLE=0

# Developer enable git mounts inside CT (0 is enabled, 1 is disabled)
DEV_GIT_MOUNT_ENABLE=1

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

# Container Hostname
CT_HOSTNAME_VAR='pihole'
# Container IP Address (192.168.1.254)
CT_IP_VAR='192.168.1.254'
# CT IP Subnet
CT_IP_SUBNET='24'
# Container Network Gateway
CT_GW_VAR='192.168.1.5'
# DNS Server
CT_DNS_SERVER_VAR='192.168.1.5'
# Container Number
CTID_VAR='254'
# Container VLAN
CT_TAG_VAR='0'
# Container Virtual Disk Size (GB)
CT_DISK_SIZE_VAR='5'
# Container allocated RAM
CT_RAM_VAR='512'
# Easy Script Section Header Body Text
SECTION_HEAD='Homelab PiHole'
#---- Do Not Edit
# Container Swap
CT_SWAP="$(( $CT_RAM_VAR / 2 ))"
# CT CPU Cores
CT_CPU_CORES="$CT_CPU_CORES_VAR"
# CT unprivileged status
CT_UNPRIVILEGED='1'
# Features (0 means none)
CT_FUSE='0'
CT_KEYCTL='0'
CT_MOUNT='0'
CT_NESTING='0'
# Startup Order
CT_STARTUP='1'
# Container Root Password ( 0 means none )
CT_PASSWORD='0'
# PVE Container OS
OSTYPE='ubuntu'
OSVERSION='21.04'

# App default UID/GUID
APP_USERNAME='home'
APP_GRPNAME='homelab'

# PiHole Password
APP_PASSWORD='ahuacate'

#---- Other Files ------------------------------------------------------------------

# Required PVESM Storage Mounts for CT
cat << 'EOF' > pvesm_required_list
EOF

#---- Body -------------------------------------------------------------------------

#---- Introduction
source ${COMMON_PVE_SOURCE}/pvesource_ct_intro.sh

#---- Setup PVE CT Variables
source ${COMMON_PVE_SOURCE}/pvesource_ct_setvmvars.sh

#---- Create OS CT
source ${COMMON_PVE_SOURCE}/pvesource_ct_createvm.sh

#---- Pre-Configuring PVE CT
section "Pre-Configure ${OSTYPE^} CT"

# #---- Configure New CT OS
source ${COMMON_PVE_SOURCE}/pvesource_ct_ubuntubasics.sh

#---- PiHole -----------------------------------------------------------------------

section "Install ${CT_HOSTNAME_VAR^}"

#---- Prerequisites

# Install pre-requisite apps
apt-get install php-curl -yqq

# Create Hash Password
PIHOLE_PASSWORD="$(echo -n ${APP_PASSWORD} | sha256sum | awk '{printf "%s",$1 }' | sha256sum | awk '{printf "%s",$1 }')"

# /etc/pihole/setupVars.conf
cat << EOF > setupVars.conf
WEBPASSWORD=${PIHOLE_PASSWORD}
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=${CT_IP}/24
IPV6_ADDRESS=
QUERY_LOGGING=true
INSTALL_WEB=true
DNSMASQ_LISTENING=single
PIHOLE_DNS_1=1.1.1.1
PIHOLE_DNS_2=1.0.0.1
PIHOLE_DNS_3=2606:4700:4700::1111
PIHOLE_DNS_4=2606:4700:4700::1001
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSSEC=true
TEMPERATUREUNIT=C
WEBUIBOXEDLAYOUT=traditional
API_EXCLUDE_DOMAINS=
API_EXCLUDE_CLIENTS=
API_QUERY_LOG_SHOW=all
API_PRIVACY_MODE=false
EOF

# Push setupVars.conf to CT
pct exec $CTID -- mkdir -p /etc/pihole
pct push $CTID ${TEMP_DIR}/setupVars.conf /etc/pihole/setupVars.conf

#---- Installing PiHole
msg "Installing PiHole..."
pct exec $CTID -- bash -c 'curl -L https://install.pi-hole.net | bash /dev/stdin --unattended'


#---- Install PiHole Add-on Updatelists (Automatic weekly list updater)
section "Update Lists add-on"

msg_box "PiHole has the capability to use remote lists. Thanks to 'Jacklul' at https://github.com/jacklul its been made a lot easier to manage those lists.

This add-on will automate list updates for you. Updates are weekly, performed on Saturday between 3:00-4:00."

# Make selection
OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" )
OPTIONS_LABELS_INPUT=( "Install Jacklul Update Lists - Recommended" "No. Do not install." )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"

if [ ${RESULTS} == TYPE01 ]; then
  # Install PiHole List Updater
  msg "Installing Jacklul Update Lists add-on..."
  source ${DIR}/source/pve_homelab_ct_pihole_settings/addon-updatelists_installer.sh
  info "Add-on status: ${YELLOW}installed${NC}"
  echo
elif [ ${RESULTS} == TYPE02 ]; then
  # Skip the step
  msg "Okay. You can always install at a later time. Moving on..."
  echo
fi


#---- Install PiHole Updater
section "PiHole Updater"

msg_box "The PiHole script keeps PiHole and Add-on SW up-to-date. Updates are weekly, performed on Monday at 03:00. If PiHole SW is updated a PVE container reboot is performed.

Default update tasks:
  --  PiHole software
  --  Jacklul PiHole-updatelists ( if installed )"

OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" )
OPTIONS_LABELS_INPUT=( "Install Automatic Updater - Recommended" "No. Do not install." )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"

if [ ${RESULTS} == TYPE01 ]; then
  # Install PiHole List Updater
  msg "Installing PiHole updater..."
  source ${DIR}/source/pve_homelab_ct_pihole_settings/update-pihole_installer.sh
  info "PiHole updater status: ${YELLOW}installed${NC}"
  echo
elif [ ${RESULTS} == TYPE02 ]; then
  # Skip the step
  msg "Okay. You can always install at a later time. Moving on..."
  echo
fi

# #---- Finish Line ------------------------------------------------------------------
section "Completion Status."

msg "Success. ${CT_HOSTNAME_VAR^} installed. Web-interface is available on:

  --  ${WHITE}http://${CT_IP}${NC} (password: ${APP_PASSWORD})\n
  --  ${WHITE}http://${CT_HOSTNAME}${NC}\n"


# Cleanup
trap cleanup EXIT