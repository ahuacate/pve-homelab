#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_guacamole.sh
# Description:  This script is for creating a Guacamole CT
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/master/scripts/pve_homelab_ct_guacamole.sh)"

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

# Check Ahuacate Check variables
if [[ $(cat /etc/postfix/main.cf | grep "### Ahuacate_Check=0.*") ]]; then
  SMTP_STATUS=0
elif [[ ! $(cat /etc/postfix/main.cf | grep "### Ahuacate_Check=0.*") ]]; then
  SMTP_STATUS=1
fi

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
CT_HOSTNAME_VAR='guacamole'
# Container IP Address (192.168.1.250)
CT_IP_VAR='192.168.1.250'
# CT IP Subnet
CT_IP_SUBNET='24'
# Container Network Gateway
CT_GW_VAR='192.168.1.5'
# DNS Server
CT_DNS_SERVER_VAR='192.168.1.5'
# Container Number
CTID_VAR='250'
# Container VLAN
CT_TAG_VAR='0'
# Container Virtual Disk Size (GB)
CT_DISK_SIZE_VAR='5'
# Container allocated RAM
CT_RAM_VAR='1024'
# Easy Script Section Header Body Text
SECTION_HEAD='Homelab Guacamole'
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

# Guacamole Password
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

# Homelab CT unprivileged mapping
if [ $CT_UNPRIVILEGED = 1 ]; then
  source ${COMMON_PVE_SOURCE}/pvesource_ct_homelab_ctidmapping.sh
fi

# #---- Configure New CT OS
# source ${COMMON_PVE_SOURCE}/pvesource_ct_ubuntubasics.sh

#---- Guacamole --------------------------------------------------------------------

section "Install ${CT_HOSTNAME_VAR^}"

#---- Prerequisites

# Start container
pct_start_waitloop

# Update locales
pct exec $CTID -- bash -c 'export LANGUAGE=en_US.UTF-8'
pct exec $CTID -- bash -c 'export LANG=en_US.UTF-8'
# pct exec $CTID -- bash -c 'export LC_ALL=en_US.UTF-8'
pct exec $CTID -- sudo locale-gen en_US.UTF-8
# pct exec $CTID -- bash -c 'export LC_ALL=C'

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

Guacamole uses MySQL for database authentication. It's required you to create a MySQL password. You have the option to input your own or use a randomly machine generated password."

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

# Downloading Install script
msg "Downloading Guacamole server..."
pct exec $CTID -- wget -q --show-progress https://raw.githubusercontent.com/MysticRyuujin/guac-install/master/guac-install.sh -P /tmp
pct exec $CTID -- sudo chmod +x /tmp/guac-install.sh

# Running Installer
msg "Running MysticRyuujin/guac-install script..."
pct exec $CTID -- sudo /tmp/guac-install.sh --mysqlpwd ${USER_PWD} --guacpwd ${USER_PWD} --nomfa --installmysql

# Check SMTP server status for emailing login credentials
if [ ${SMTP_STATUS} = 0 ]; then
  EMAIL_RECIPIENT=$(pveum user list | awk -F " │ " '$1 ~ /root@pam/' | awk -F " │ " '{ print $3 }')
  msg_box "#### PLEASE READ CAREFULLY - EMAIL GUACAMOLE ADMIN CREDENTIALS ####\n
  Your Guacamole login credentials can be emailed to this PVE hosts system administrator : ${EMAIL_RECIPIENT}
  The system administrator can then forward the email(s) to you. The email will include the following information:

    Guacamole Login Credentials

  $(printf "  --  Guacamole URL|http://${CT_IP}:8080/guacamole
    --  Username|guacadmin
    --  Password|guacadmin
    --  MySQL Password|${USER_PWD}" | column -t -s "|" | indent2)"
  echo
  while true; do
    read -p "Email ${CT_HOSTNAME_VAR^} login credentials to your system’s administrator [y/n]? " -n 1 -r YN
    echo
    case $YN in
      [Yy]*)
        printf "====================   GUACAMOLE LOGIN CREDENTIALS   ====================

        For administrator access to your Guacamole host the login credentials
        details are:

        $(printf "  --  Guacamole URL|http://${CT_IP}:8080/guacamole
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
pct exec $CTID -- reboot

#---- Finish Line ------------------------------------------------------------------
section "Completion Status."

msg "Success. ${CT_HOSTNAME_VAR^} is now rebooting so be patient. Web-interface is available at:

$(printf "  --  Guacamole URL|http://${CT_IP}:8080/guacamole
  --  Username|guacadmin
  --  Password|guacadmin
  --  MySQL Password|${USER_PWD}" | column -t -s "|" | indent2)

Immediately change 'guacadmin' login credentials or disable guacadmin after install. Store your MySQL and Guacamole credentials in a safe place.\n"

# Cleanup
trap cleanup EXIT