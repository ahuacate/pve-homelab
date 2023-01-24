#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_guacamole_installer.sh
# Description:  This script is for creating a Guacamole CT
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#---- Source Github
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/main/pve_homelab_installer.sh)"

#---- Source local Git
# /mnt/pve/nas-01-git/ahuacate/pve-homelab/pve_homelab_installer.sh

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------

# Check SMTP Status
check_smtp_status

#---- Static Variables -------------------------------------------------------------

# Easy Script Section Head
SECTION_HEAD='PVE Guacamole'

# PVE host IP
PVE_HOST_IP=$(hostname -i)
PVE_HOSTNAME=$(hostname)

# SSHd Status (0 is enabled, 1 is disabled)
SSH_ENABLE=1

# Developer enable git mounts inside CT  (0 is enabled, 1 is disabled)
DEV_GIT_MOUNT_ENABLE=1

# Set file source (path/filename) of preset variables for 'pvesource_ct_createvm.sh'
PRESET_VAR_SRC="$( dirname "${BASH_SOURCE[0]}" )/$( basename "${BASH_SOURCE[0]}" )"

#---- Other Variables --------------------------------------------------------------

#---- Common Machine Variables
# VM Type ( 'ct' or 'vm' only lowercase )
VM_TYPE='ct'
# Use DHCP. '0' to disable, '1' to enable.
NET_DHCP='1'
#  Set address type 'dhcp4'/'dhcp6' or '0' to disable.
NET_DHCP_TYPE='dhcp4'
# CIDR IPv4
CIDR='24'
# CIDR IPv6
CIDR6='64'
# SSHd Port
SSH_PORT='22'

#----[COMMON_GENERAL_OPTIONS]
# Hostname
HOSTNAME='guacamole'
# Description for the Container (one word only, no spaces). Shown in the web-interface CT’s summary. 
DESCRIPTION=''
# Virtual OS/processor architecture.
ARCH='amd64'
# Allocated memory or RAM (MiB).
MEMORY='1024'
# Limit number of CPU sockets to use.  Value 0 indicates no CPU limit.
CPULIMIT='0'
# CPU weight for a VM. Argument is used in the kernel fair scheduler. The larger the number is, the more CPU time this VM gets.
CPUUNITS='1024'
# The number of cores assigned to the vm/ct. Do not edit - its auto set.
CORES='1'

#----[COMMON_NET_OPTIONS]
# Bridge to attach the network device to.
BRIDGE='vmbr0'
# A common MAC address with the I/G (Individual/Group) bit not set. 
HWADDR=""
# Controls whether this interface’s firewall rules should be used.
FIREWALL='1'
# VLAN tag for this interface (value 0 for none, or VLAN[2-N] to enable).
TAG='0'
# VLAN ids to pass through the interface
TRUNKS=""
# Apply rate limiting to the interface (MB/s). Value "" for unlimited.
RATE=""
# MTU - Maximum transfer unit of the interface.
MTU=""

#----[COMMON_NET_DNS_OPTIONS]
# Nameserver server IP (IPv4 or IPv6) (value "" for none).
NAMESERVER='192.168.1.5'
# Search domain name (local domain)
SEARCHDOMAIN='local'

#----[COMMON_NET_STATIC_OPTIONS]
# IP address (IPv4). Only works with static IP (DHCP=0).
IP='192.168.1.250'
# IP address (IPv6). Only works with static IP (DHCP=0).
IP6=''
# Default gateway for traffic (IPv4). Only works with static IP (DHCP=0).
GW='192.168.1.5'
# Default gateway for traffic (IPv6). Only works with static IP (DHCP=0).
GW6=''

#---- PVE CT
#----[CT_GENERAL_OPTIONS]
# Unprivileged container status 
CT_UNPRIVILEGED='1'
# Memory swap
CT_SWAP='512'
# OS
CT_OSTYPE='ubuntu'
# Onboot startup
CT_ONBOOT='1'
# Timezone
CT_TIMEZONE='host'
# Root credentials (leave blank for no pwd)
CT_PASSWORD=''
# Virtual OS/processor architecture.
CT_ARCH='amd64'

#----[CT_FEATURES_OPTIONS]
# Allow using fuse file systems in a container.
CT_FUSE='0'
# For unprivileged containers only: Allow the use of the keyctl() system call.
CT_KEYCTL='0'
# Allow mounting file systems of specific types. (Use 'nfs' or 'cifs' or 'nfs;cifs' for both or leave empty "")
CT_MOUNT=''
# Allow nesting. Best used with unprivileged containers with additional id mapping.
CT_NESTING='0'
# A public key for connecting to the root account over SSH (insert path).

#----[CT_ROOTFS_OPTIONS]
# Virtual Disk Size (GB).
CT_SIZE='5'
# Explicitly enable or disable ACL support.
CT_ACL='0'

#----[CT_STARTUP_OPTIONS]
# Startup and shutdown behavior ( '--startup order=1,up=1,down=1' ). Order is a non-negative number defining the general startup order. Up=1 means first to start up. Shutdown in done with reverse ordering so down=1 means last to shutdown.
CT_ORDER='2'
CT_UP='2'
CT_DOWN='2'

#----[CT_NET_OPTIONS]
# Name of the network device as seen from inside the VM/CT.
CT_NAME='eth0'
CT_TYPE='veth'

#----[CT_OTHER]
# OS Version (NOTE: Guacamole will not install on 22.04 - SSL3 errors with Mysql)
CT_OSVERSION='22.04'
# CTID numeric ID of the given container.
CTID='250'

#----[App_UID_GUID]
# App user
APP_USERNAME='home'
# App user group
APP_GRPNAME='homelab'


#---- Other Files ------------------------------------------------------------------

# Required PVESM Storage Mounts for CT ( new version )
unset pvesm_required_LIST
pvesm_required_LIST=()
while IFS= read -r line; do
  [[ "$line" =~ ^\#.*$ ]] && continue
  pvesm_required_LIST+=( "$line" )
done << EOF
# Example
EOF

#---- Body -------------------------------------------------------------------------

#---- Introduction
source ${COMMON_PVE_SRC_DIR}/pvesource_ct_intro.sh

#---- Setup PVE CT Variables
# Ubuntu NAS (all)
source ${COMMON_PVE_SRC_DIR}/pvesource_set_allvmvars.sh

#---- Create OS CT
source ${COMMON_PVE_SRC_DIR}/pvesource_ct_createvm.sh

#---- Configure New CT OS
source ${COMMON_PVE_SRC_DIR}/pvesource_ct_ubuntubasics.sh

# Homelab CT unprivileged mapping
if [ $CT_UNPRIVILEGED = 1 ]; then
  source ${COMMON_PVE_SRC_DIR}/pvesource_ct_homelab_ctidmapping.sh
fi

#---- Guacamole --------------------------------------------------------------------

section "Install ${HOSTNAME^}"

#---- Prerequisites

# Start container
pct_start_waitloop

# Update locales
pct exec $CTID -- bash -c 'export LANGUAGE=en_US.UTF-8'
pct exec $CTID -- bash -c 'export LANG=en_US.UTF-8'
pct exec $CTID -- sudo locale-gen en_US.UTF-8

# Update Ubuntu
pct exec $CTID -- apt-get update -yqq > /dev/null
pct exec $CTID -- apt-get upgrade -yqq > /dev/null

# Add Packages
msg "Updating ${OSTYPE^} packages (be patient, might take a while)..."
pct exec $CTID -- apt-get install software-properties-common -qqy > /dev/null
pct exec $CTID -- add-apt-repository -y universe
pct exec $CTID -- apt-get -qqy update > /dev/null

#---- Install Guacamole
msg_box "#### PLEASE READ CAREFULLY ####\n
This install uses the 'MysticRyuujin' installation script. Thanks to 'MysticRyuujin' for maintaining this script.

Guacamole uses MySQL for database authentication. It's required you create a MySQL password. You have the option to input your own or use a randomly machine generated password."

# Create a MySQL Password
msg "Create a MySQL password..."
OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" )
OPTIONS_LABELS_INPUT=( "Random Password - random machine generated password ( Recommended )" "Other - create your own password" )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"
if [ ${RESULTS} == TYPE01 ]; then
  # Machine generated password
  make_userpwd
elif [ ${RESULTS} == TYPE02 ]; then
  # Input a Password
  input_userpwd_val
fi

# 2FA authentication
msg_box "#### PLEASE READ CAREFULLY ####\n
Guacamole supports Duo or TOTP two-factor authentication as a second authentication factor. We recommend you use two-factor authentication with a YubiKey or Google Authenticator.

If you are unsure about two-factor authentication select 'none'. You can always configure TOTP or Duo at a later stage using our Guacamole Toolbox."

# Select a two-factor authentication
msg "Select a two-factor authentication type..."
OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" "TYPE03" )
OPTIONS_LABELS_INPUT=( "Duo - installs the Duo extension" "TOTP - installs the TOTP extension (YubiKey or Google MFA)" "None - no two-factor authentication" )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"
if [ ${RESULTS} == TYPE01 ]; then
  # Two-factor type
  MFA='duo'
elif [ ${RESULTS} == TYPE02 ]; then
  # Two-factor type
  MFA='totp'
elif [ ${RESULTS} == TYPE03 ]; then
  # Two-factor type
  MFA='nomfa'
fi

# Run Installer
msg "Running MysticRyuujin/guac-install script (be patient, might take a while)..."
pct push $CTID ${SRC_DIR}/guacamole/guacamole_sw.sh /tmp/guacamole_sw.sh -perms 755
pct exec $CTID -- bash -c "export REPO_PKG_NAME=${REPO_PKG_NAME} APP_USERNAME=${APP_USERNAME} APP_GRPNAME=${APP_GRPNAME} MFA=${MFA} USER_PWD=${USER_PWD} && /tmp/guacamole_sw.sh"

# Check SMTP server status for emailing login credentials
if [ ${SMTP_STATUS} = '1' ]; then
  EMAIL_RECIPIENT=$(pveum user list | awk -F " │ " '$1 ~ /root@pam/' | awk -F " │ " '{ print $3 }')
  msg_box "#### PLEASE READ CAREFULLY - EMAIL GUACAMOLE ADMIN CREDENTIALS ####\n
  Your Guacamole login credentials can be emailed to this PVE hosts system administrator : ${EMAIL_RECIPIENT}
  The system administrator can then forward the email(s) to you. The email will include the following information:

    Guacamole Login Credentials

  $(printf "  --  Guacamole URL by IP|http://${IP}:8080/guacamole
    --  Guacamole URL by hostname|http://guacamole.$(hostname -d):8080/guacamole (Recommended URL)
    --  Username|guacadmin
    --  Password|guacadmin
    --  MySQL Password|${USER_PWD}" | column -t -s "|" | indent2)"
  echo
  while true; do
    read -p "Email ${HOSTNAME^} login credentials to your systems administrator [y/n]? " -n 1 -r YN
    echo
    case $YN in
      [Yy]*)
        printf "====================   GUACAMOLE LOGIN CREDENTIALS   ====================

        For administrator access to your Guacamole host the login credentials
        details are:

        $(printf "  --  Guacamole URL by IP|http://${IP}:8080/guacamole
          --  Guacamole URL by hostname|http://guacamole.$(hostname -d):8080/guacamole (Recommended URL)
          --  Username|guacadmin
          --  Password|guacadmin
          --  MySQL Password|${USER_PWD}" | column -t -s "|" | indent2)\n" | mail -s "Login credentials for Guacamole host." -- ${EMAIL_RECIPIENT}
        info "Guacamole login credentials sent to: ${YELLOW}${EMAIL_RECIPIENT}${NC}"
        echo
        break
        ;;
      [Nn]*)
        info "You have chosen to skip this step. Not sending any email(s)."
        echo
        break
        ;;
      *)
        warn "Error! Entry must be 'y' or 'n'. Try again..."
        echo
        ;;
    esac
  done
fi

# Reboot the CT
pct_stop_waitloop
pct_start_waitloop

#---- Finish Line ------------------------------------------------------------------
section "Completion Status."

# Check for ZFS install error
if [[ $(pvesm status | grep '^local-zfs') ]]; then
  warn "If you are seeing this warning its because your PVE is on ZFS. At the time of writing mysql-server fails when the LXC is on ZFS. Guacamole installs on EXT4 without issues."
fi

#---- Set display text
unset display_msg1
# Web access URL
if [ -n "${IP}" ] && [ ! ${IP} == 'dhcp' ]; then
  display_msg1+=( "http://${IP}:8080/guacamole" )
elif [ -n "${IP6}" ] && [ ! ${IP6} == 'dhcp' ]; then
  display_msg1+=( "http://${IP6}:8080/guacamole" )
elif [ ${IP} == 'dhcp' ] || [ ${IP6} == 'dhcp' ]; then
  display_msg1+=( "http://$(pct exec $CTID -- bash -c "hostname -I | sed 's/ //g'"):8080/guacamole (not static)" )
  # display_msg1+=( "We recommend the Guacamole server be set with a STATIC IP ADDRESS to function properly. Set a static IP using DHCP reservation at your router or DHCP server." )
fi
display_msg1+=( "http://guacamole.$(hostname -d):8080/guacamole (Recommended URL)" )

msg "${HOSTNAME^} installation was a success. Web-interface is available at:

$(printf '%s\n' "${display_msg1[@]}" | indent2)

Guacamole web interface login password:

$(printf "  --  Username|guacadmin
  --  Password|guacadmin
  --  MySQL Password|${USER_PWD}" | column -t -s "|" | indent2)

#### IMPORTANT ####
Immediately change 'guacadmin' login credentials or disable 'guacadmin'. Store your MySQL and Guacamole credentials in a safe place."
echo
#-----------------------------------------------------------------------------------