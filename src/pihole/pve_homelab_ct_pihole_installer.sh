#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_pihole_installer.sh
# Description:  This script is for creating a Pi-Hole CT
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#---- Source Github
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/main/pve_homelab_installer.sh)"

#---- Source local Git
# /mnt/pve/nas-01-git/ahuacate/pve-homelab/pve_homelab_installer.sh

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

# Easy Script Section Head
SECTION_HEAD='PVE Pi-Hole'

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
HOSTNAME='pihole'
# Description for the Container (one word only, no spaces). Shown in the web-interface CT’s summary. 
DESCRIPTION=''
# Virtual OS/processor architecture.
ARCH='amd64'
# Allocated memory or RAM (MiB).
MEMORY='2048'
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
IP='192.168.1.6'
# IP address (IPv6). Only works with static IP (DHCP=0).
IP6=''
# Default gateway for traffic (IPv4). Only works with static IP (DHCP=0).
GW='192.168.1.5'
# Default gateway for traffic (IPv6). Only works with static IP (DHCP=0).
GW6=''

#---- PVE CT
#----[CT_GENERAL_OPTIONS]
# Unprivileged container. '0' to disable, '1' to enable/yes.
CT_UNPRIVILEGED='1'
# Memory swap
CT_SWAP='512'
# OS
CT_OSTYPE='ubuntu'
# Onboot startup
CT_ONBOOT='1'
# Timezone
CT_TIMEZONE='host'
# Root credentials
CT_PASSWORD='ahuacate'
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
CT_ACL='1'

#----[CT_STARTUP_OPTIONS]
# Startup and shutdown behavior ( '--startup order=1,up=1,down=1' ).
# Order is a non-negative number defining the general startup order. Up=1 means first to start up. Shutdown in done with reverse ordering so down=1 means last to shutdown.
# Up: Startup delay. Defines the interval between this container start and subsequent containers starts. For example, set it to 240 if you want to wait 240 seconds before starting other containers.
# Down: Shutdown timeout. Defines the duration in seconds Proxmox VE should wait for the container to be offline after issuing a shutdown command. By default this value is set to 60, which means that Proxmox VE will issue a shutdown request, wait 60s for the machine to be offline, and if after 60s the machine is still online will notify that the shutdown action failed. 
CT_ORDER='1'
CT_UP='30'
CT_DOWN='60'

#----[CT_NET_OPTIONS]
# Name of the network device as seen from inside the VM/CT.
CT_NAME='eth0'
CT_TYPE='veth'

#----[CT_OTHER]
# OS Version (NOTE: Pihole will not install on 22.04)
CT_OSVERSION='22.04'
# CTID numeric ID of the given container.
CTID='254'

#----[App_UID_GUID]
# App user
APP_USERNAME='home'
# App user group
APP_GRPNAME='homelab'
# APP Pi-Hole Pwd
APP_PASSWORD='ahuacate'

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
source $COMMON_PVE_SRC_DIR/pvesource_ct_intro.sh

#---- Setup PVE CT Variables
# Ubuntu NAS (all)
source $COMMON_PVE_SRC_DIR/pvesource_set_allvmvars.sh

#---- Create OS CT
source $COMMON_PVE_SRC_DIR/pvesource_ct_createvm.sh

#---- Configure New CT OS
source $COMMON_PVE_SRC_DIR/pvesource_ct_ubuntubasics.sh

#---- Pi-Hole -----------------------------------------------------------------------

section "Install Pi-Hole"

#---- Prerequisites
# Create Hash Password
PIHOLE_PASSWORD="$(echo -n "$APP_PASSWORD" | sha256sum | awk '{printf "%s",$1 }' | sha256sum | awk '{printf "%s",$1 }')"

# DHCP server
interface=$(ip r | grep default | awk '/default/ {print $5}')
DHCP_SERVER_IP=$(nmap --script broadcast-dhcp-discover -e $interface 2> /dev/null |  grep 'Router' | sed 's/^.*: //' | sed -r 's/\s+//g')

# Local network CIDR
CIDR_NOTA=$(echo "$DHCP_SERVER_IP" | awk -F'.' -v octet="0" '{OFS=FS}{ print $1, $2, octet, octet"/16" }')

# Create installer preset /etc/pihole/setupVars.conf
cat << EOF > $DIR/setupVars.conf 
WEBPASSWORD=${PIHOLE_PASSWORD}
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=${IP}/24
IPV6_ADDRESS=
QUERY_LOGGING=true
INSTALL_WEB=true
DNSMASQ_LISTENING=single
PIHOLE_DNS_1=127.0.0.1#5335
PIHOLE_DNS_2=
PIHOLE_DNS_3=
PIHOLE_DNS_4=
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSSEC=true
TEMPERATUREUNIT=C
WEBUIBOXEDLAYOUT=traditional
API_EXCLUDE_DOMAINS=
API_EXCLUDE_CLIENTS=
API_QUERY_LOG_SHOW=all
API_PRIVACY_MODE=false
CONDITIONAL_FORWARDING=true
CONDITIONAL_FORWARDING_IP=${DHCP_SERVER_IP}
CONDITIONAL_FORWARDING_DOMAIN=$(hostname -d)
CONDITIONAL_FORWARDING_REVERSE=${CIDR_NOTA}
EOF

# Push Pi-Hole setupVars.conf to CT
pct exec $CTID -- mkdir -p /etc/pihole
pct push $CTID $DIR/setupVars.conf /etc/pihole/setupVars.conf

# Create SW installation package script
cat << EOF > $DIR/installpkg.sh 
#!/usr/bin/env bash

# Install Pi-Hole
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended

# Install unbound
apt-get install unbound -y

# Signal FTL to adhere to this limit
echo "edns-packet-max=1232" > /etc/dnsmasq.d/99-edns.conf

# Start your local recursive server
systemctl restart unbound

# Disabled 
# systemctl disable unbound-resolvconf.service
# systemctl stop unbound-resolvconf.service
EOF

# Push unbound Pi-Hole config file to CT
pct exec $CTID -- mkdir -p /etc/unbound/unbound.conf.d
pct push $CTID $SRC_DIR/pihole/config/unbound_pihole.conf /etc/unbound/unbound.conf.d/pi-hole.conf


#---- Installing Pi-Hole
msg "Installing Pi-Hole..."

# Run the SW installation package script
pct push $CTID $DIR/installpkg.sh /tmp/installpkg.sh -perms 755
pct exec $CTID -- bash -c "/tmp/installpkg.sh"
echo

# Identify PVE hosts
source $COMMON_PVE_SRC_DIR/pvesource_identify_pvehosts.sh
msg "Adding static PVE machine hostnames to Pi-Hole DNS records..."
while IFS=',' read -r pve_hostname pve_ip other
do
  # Add to /etc/pihole/custom.list
  pct exec $CTID -- bash -c "echo \"${pve_ip} ${pve_hostname}.$(hostname -d)\" >> /etc/pihole/custom.list"
done < <( printf '%s\n' "${pve_node_LIST[@]}" )
echo

#---- Set additional Conditional Forwarding addresses
section "Conditional Forwarding"

display_msg1=( "${CIDR_NOTA}:${DHCP_SERVER_IP}:$(hostname -d)" )
msg_box "#### PLEASE READ CAREFULLY - Other DHCP Servers ####\n\nPiHole requires all your network DHCP server IPv4 addresses in order to configure conditional forwarding. If not configured Pi-hole won't be able to determine all the names of devices on your local network. Currently only your primary router DHCP server has been identified.\n\n$(printf '%s\n' "${display_msg1[@]}" | column -s ":" -t -N "Network CIDR notation,DHCP Server IP,Local domain name" | indent2)\n\nYou must now input all additional DHCP server IPv4 addresses on your network.\n\nThis includes all pfSense DHCP servers IP addresses (i.e LAN-vpngate-world --> 192.168.30.5)."

msg "Add additional DHCP server IP addresses..."
j=2
dhcp_server_ip_LIST=()
while true
do
  # Display configured additional DHCP servers
  if [ ! ${#dhcp_server_ip_LIST[@]} = 0 ]
  then
    msg_box "Conditional Forwarding - Additional DHCP Servers\n\n$(printf '%s\n' "${dhcp_server_ip_LIST[@]}" | column -s ":" -t -N "Network CIDR notation,DHCP Server IP,Description" | indent2)"
  fi
  unset OPTIONS_VALUES_INPUT
  unset OPTIONS_LABELS_INPUT
  OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" )
  OPTIONS_LABELS_INPUT=( "Add a network DHCP server IP address" \
  "No - Nothing to add" )
  makeselect_input2
  singleselect SELECTED "$OPTIONS_STRING"

  if [ "$RESULTS" = 'TYPE01' ]
  then
    # Add a DHCP server IP address
    read -p "Enter a network DHCP server IPv4 address: " -e DHCP_SERVER_IP_EXTRA
    FAIL_MSG="The DHCP address 'appears' to be not valid. A valid DHCP IP address is when all of the following constraints are satisfied:\n
    --  it meets the IPv4 or IPv6 standard.\n
    Try again..."
    PASS_MSG="DHCP IP server is set: ${YELLOW}$DHCP_SERVER_IP_EXTRA${NC}"
    result=$(valid_ip "$DHCP_SERVER_IP_EXTRA" > /dev/null 2>&1)
    if [ $? -ne 0 ]
    then
      warn "$FAIL_MSG"
      echo
    else
      while true
      do
        read -p "Accept DHCP IP '$DHCP_SERVER_IP_EXTRA' [y/n]?: " -n 1 -r YN
        echo
        case $YN in
          [Yy]*)
            info "$PASS_MSG"
            # Local network CIDR
            CIDR_NOTA_EXTRA=$(echo "$DHCP_SERVER_IP_EXTRA" | awk -F'.' -v octet="0" '{OFS=FS}{ print $1, $2, octet, octet"/16" }')
            dhcp_server_ip_LIST+=( "${CIDR_NOTA_EXTRA}:${DHCP_SERVER_IP_EXTRA}:DHCP Server $j" )
            (( j=j+1 ))
            echo
            break
            ;;
          [Nn]*)
            msg "Try again..."
            echo
            break
            ;;
          *)
            warn "Error! Entry must be 'y' or 'n'. Try again..."
            echo
            ;;
        esac
      done
      echo
    fi
  elif [ "$RESULTS" = 'TYPE02' ]
  then
    # Finished. Nothing more to add
    break
  fi
done

# Creating PiHole custom entry
if [ ! ${#dhcp_server_ip_LIST[@]} = 0 ]
then
  msg "Creating custom entry to Pi-Hole Conditional Forwarding records..."
  # Add router to /etc/dnsmasq.d/01-custom.conf
  ARPA_OCTET=$(echo "$DHCP_SERVER_IP" | awk -F'.' 'BEGIN {OFS = FS} { print $1,$2 }')
  pct exec $CTID -- bash -c "echo \"server=/${ARPA_OCTET}.in-addr.arpa/${DHCP_SERVER_IP} # UniFi UGS/UDM router\" >> /etc/dnsmasq.d/01-custom.conf"
  # Add additional DHCP server IP addresses to /etc/dnsmasq.d/01-custom.conf
  while IFS=',' read -r cidr dhcp_ip desc
  do
    ARPA_OCTET=$(echo "$dhcp_ip" | awk -F'.' 'BEGIN {OFS = FS} { print $1,$2 }')
    pct exec $CTID -- bash -c "echo \"server=/local/${dhcp_ip} # ${desc}\" >> /etc/dnsmasq.d/01-custom.conf"
    pct exec $CTID -- bash -c "echo \"server=/${ARPA_OCTET}.in-addr.arpa/${dhcp_ip} # ${desc}\" >> /etc/dnsmasq.d/01-custom.conf"
  done < <( printf '%s\n' "${dhcp_server_ip_LIST[@]}" )
  pct exec $CTID -- bash -c "echo \"strict-order\" >> /etc/dnsmasq.d/01-custom.conf"
  echo
fi

#---- Install Pi-Hole Add-on Update lists (Automatic weekly list updater)
section "Pi-Hole adlist management"

msg_box "#### PLEASE READ CAREFULLY - Jacklul Update adLists ####\n\nPiHole can use remotely sourced blocking adlists. Thanks to 'Jacklul' at https://github.com/jacklul list management has been made a lot easier. Updates are weekly, performed on Saturday between 3:00-4:00."

# Make selection
OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" )
OPTIONS_LABELS_INPUT=( "Install Jacklul Update adLists - Recommended" "None. Do not install" )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"

if [ "$RESULTS" = 'TYPE01' ]
then
  # Install Pi-Hole List Updater
  msg "Installing Jacklul Update Lists add-on..."
  source $SRC_DIR/pihole/config/addon-updatelists_installer.sh
  info "Add-on status: ${YELLOW}installed${NC}"
  echo
elif [ "$RESULTS" = 'TYPE02' ]
then
  # Skip the step
  msg "Okay. You can always install at a later time. Moving on..."
  echo
fi


#---- Install Pi-Hole Updater
section "Pi-Hole & Adlist Updater"

msg "Installing Pi-Hole updater..."
source $SRC_DIR/pihole/config/update-pihole_installer.sh
info "Pi-Hole updater status: ${YELLOW}installed${NC}"
echo

#---- Finish Line ------------------------------------------------------------------
section "Completion Status"

#---- Set display text
unset display_msg1
unset display_msg2
# Web access URL
if [ -n "${IP}" ] && [ ! "$IP" = 'dhcp' ]
then
  display_msg1+=( "http://$IP/admin" )
  display_msg2+=( "$IP" )
elif [ -n "${IP6}" ] && [ ! "$IP6" = 'dhcp' ]
then
  display_msg1+=( "http://$IP6/admin" )
  display_msg2+=( "$IP6" )
elif [ "$IP" = 'dhcp' ] || [ "$IP6" = 'dhcp' ]
then
  display_msg1+=( "http://$(pct exec $CTID -- bash -c "hostname -I | sed 's/ //g'")/admin (not static)" )
  display_msg1+=( "Pi-Hole requires a STATIC IP ADDRESS to function properly. Configure a static IP using DHCP reservation at your DHCP server. Our default Pi-Hole DNS IP is 192.168.1.6" )
  display_msg2+=( "Use the static IP DHCP reservation address (i.e 192.168.1.6)." )
fi
display_msg1+=( "http://pi.hole/admin (Recommended URL)" )

msg_box "${HOSTNAME^} installation was a success. Web-interface is available at:

$(printf '%s\n' "${display_msg1[@]}" | indent2)

Pi-Hole web interface login password:

$(echo "${APP_PASSWORD}" | indent2)

You must configure your UniFi UGS/UDM, router and pfSense DNS to use the PiHole IP address:

$(printf '%s\n' "${display_msg2[@]}" | indent2)

Pi-Hole web interface password can be reset via the command line on your Pi-Hole. This can be done locally or over SSH with command 'pihole -a -p'. You will be prompted for the new password. More information about configuring ${HOSTNAME^} is available here:

$(echo "https://github.com/ahuacate/home-lab" | indent2)"
#-----------------------------------------------------------------------------------