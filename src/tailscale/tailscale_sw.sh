#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     tailscale_sw.sh
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
# Local network
LOCAL_NET=$(hostname -I | awk -F'.' -v OFS="." '{ print $1,$2,"0.0/24" }')

#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Run Bash Header
source $COMMON/bash/src/basic_bash_utility.sh

# Update locales
sudo locale-gen en_US.UTF-8

# Install prerequisites
apt-get install ca-certificates wget -y

# Update locales
sudo locale-gen en_US.UTF-8

# Add Packages
apt-get install software-properties-common -y 2> /dev/null
apt-get install unzip -y 2> /dev/null
apt-get install fontconfig -y 2> /dev/null
apt-get install curl -y 2> /dev/null

# Add Google font package
wget -O /tmp/fonts.zip https://fonts.google.com/download?family=Open%20Sans
mkdir -p /usr/share/fonts/googlefonts
mkdir -p /usr/share/fonts/opentype
unzip /tmp/fonts.zip -d /usr/share/fonts/googlefonts
chmod -R --reference=/usr/share/fonts/opentype /usr/share/fonts/googlefonts
sudo fc-cache -fv

# Install video drivers
if [ "$(ls -l /dev/dri | grep renderD128 > /dev/null; echo $?)" = 0 ]
then
	GPU=$(lspci | grep VGA | cut -d ":" -f3 | sed -e 's/^[ \t]*//')
	# Intel GPU
	if [[ "$GPU" =~ ^Intel.* ]]
	then
		# Install drivers
		# apt-get install i965-va-driver -y
		apt-get install intel-media-va-driver-non-free -y
	fi
fi

# Install ffmpeg
apt-get install ffmpeg -y


#---- Create new user

# Add user
useradd -m -p $(perl -e 'print crypt($ARGV[0], "password")' ahuacate) admin
usermod -aG sudo admin
usermod -s /bin/bash admin
sudo -u admin xdg-user-dirs-update
echo "admin ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/admin

#---- Install RDP SW

#  Install the desktop environment
apt-get install xfce4 xfce4-goodies -y
# Fix /etc/nsswitch.conf after xfce4 install
sed -i 's/hosts:.*/hosts:          files dns/g' /etc/nsswitch.conf
# Install X stuff
apt-get install xorg dbus-x11 x11-xserver-utils -y
# Install XRDP on Ubuntu
apt-get install xrdp ufw -y
# Edit /etc/xrdp/xrdp.ini
echo 'exec startxfce4' >> /etc/xrdp/xrdp.ini
systemctl restart xrdp.service
# Set RDP display
update-alternatives --set x-session-manager /usr/bin/xfce4-session
# Add the xrdp user to the “ssl-cert” group
usermod -a -G ssl-cert xrdp
systemctl restart xrdp
# Configure System firewall
ufw allow from 192.168.0.0/24 to any port 3389
ufw reload

# Fix - Authentication Required to Create Managed Color Device
cat << EOF > /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf
polkit.addRule(function(action, subject) {
 if ((action.id == "org.freedesktop.color-manager.create-device" ||
 action.id == "org.freedesktop.color-manager.create-profile" ||
 action.id == "org.freedesktop.color-manager.delete-device" ||
 action.id == "org.freedesktop.color-manager.delete-profile" ||
 action.id == "org.freedesktop.color-manager.modify-device" ||
 action.id == "org.freedesktop.color-manager.modify-profile") &&
 subject.isInGroup("{users}")) {
 return polkit.Result.YES;
 }
 });
EOF


#---- Install firefox

# Add the Mozilla Team PPA
add-apt-repository ppa:mozillateam/ppa -y 2> /dev/null
# Increase the priority of it's firefox package
printf 'Package: firefox\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1500\n' | tee /etc/apt/preferences.d/mozilla-firefox
# Install Firefox
apt-get install firefox -y
# Copy Firefox bookmark preset file to CT
cp $DIR/config/bookmarks-ahuacate.json /home/home/Desktop/bookmarks-ahuacate.json


#---- Configure audio

wget http://c-nergy.be/downloads/xRDP/xrdp-installer-1.4.2.zip -P /tmp
unzip /tmp/xrdp-installer-1.4.2.zip -d /tmp
sleep 1
chmod +x /tmp/xrdp-installer-1.4.2.sh
su -c '/tmp/xrdp-installer-1.4.2.sh -s' admin


#---- Configure Home User profile

if [ "$(ls -l /dev/dri | grep renderD128 > /dev/null; echo $?)" = 0 ]
then
	GPU=$(lspci | grep VGA | cut -d ":" -f3 | sed -e 's/^[ \t]*//')
	# Intel GPU
	if [[ "$GPU" =~ ^Intel.* ]]
	then
		# Set user environment variable
		# echo 'export LIBVA_DRIVER_NAME=i965' >> /home/admin/.profile
		echo 'export LIBVA_DRIVER_NAME=iHD' >> /home/admin/.profile
		echo 'export MOZ_X11_EGL=1' >> /home/admin/.profile
		# echo 'export MOZ_DISABLE_RDD_SANDBOX=1' >> /home/admin/.profile
	fi
fi


#---- Configure firewall
sudo ufw allow $SSH_PORT
sudo ufw allow from $LOCAL_NET to any port $SSH_PORT
# Optional additional ports
sudo ufw allow in on tailscale0  # Allow Tailscale
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

#---- Install Tailscale

# Download Tailscale install script
bash -c "$(curl -fsSL https://tailscale.com/install.sh)" &>/dev/null || exit

# Reboot CT
reboot
#-----------------------------------------------------------------------------------