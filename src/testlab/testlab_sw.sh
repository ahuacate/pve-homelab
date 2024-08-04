#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     testlab_sw.sh
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
PORT_80=80
PORT_443=443
# Local network
LOCAL_NET=$(hostname -I | awk -F'.' -v OFS="." '{ print $1,$2,"0.0/24" }')

#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Run update & upgrade
apt-get update && apt-get upgrade -y
apt-get install apt-transport-https -y

# Run Bash Header
source $COMMON/bash/src/basic_bash_utility.sh

#---- Install nginx
apt-get install nginx -y

# Stopping system.d 'nginx' unit
if [ "$(systemctl is-active nginx)" == "active" ]
then
  systemctl stop nginx
  while ! [[ "$(systemctl is-active nginx)" == "inactive" ]]
  do
    echo -n .
  done
fi

# Add group nginx
sudo useradd -r -s /sbin/nologin nginx

# Disable the Default Configuration
rm /etc/nginx/sites-enabled/default

# Create dirs
mkdir -p /var/www/test_site # Create the Web Root Directory
mkdir -p /etc/nginx/sites-available # Make site folder
mkdir -p /etc/nginx/ssl # Make SSL folder

# Copy Web files
cp $DIR/config/index_port_80.html /var/www/test_site/
cp $DIR/config/index_port_443.html /var/www/test_site/
cp $DIR/config/test_site /etc/nginx/sites-available/test_site

# Set SSL Cert & Key permissions
if [ ! -f "/etc/nginx/ssl/test_site.crt" ]; then
    touch /etc/nginx/ssl/test_site.crt
    chown root:nginx /etc/nginx/ssl/test_site.crt
    chmod 640 /etc/nginx/ssl/test_site.crt

else
    chmod 644 /etc/nginx/ssl/test_site.crt
    chown root:nginx /etc/nginx/ssl/test_site.crt
    chmod 640 /etc/nginx/ssl/test_site.crt
fi
if [ ! -f "/etc/nginx/ssl/test_site.key" ]; then
    touch /etc/nginx/ssl/test_site.key
    chown root:nginx /etc/nginx/ssl/test_site.key
    chmod 640 /etc/nginx/ssl/test_site.key
else
    chown root:nginx /etc/nginx/ssl/test_site.key
    chmod 640 /etc/nginx/ssl/test_site.key
fi

# Verify Permissions
chown -R www-data:www-data /var/www/test_site
chmod -R 755 /var/www/test_site
chown -R root:nginx /etc/nginx/ssl
chmod 750 /etc/nginx/ssl

# Create a symbolic link to enable the site configuration
ln -s /etc/nginx/sites-available/test_site /etc/nginx/sites-enabled/

# Test and Reload nginx
nginx -t

# Starting system.d 'nginx.service' unit
if [ "$(systemctl is-active nginx.service)" == "inactive" ]
then
  systemctl start nginx.service
  while ! [[ "$(systemctl is-active nginx.service)" == "active" ]]
  do
    echo -n .
  done
fi


#---- Configure firewall

# Configure the Firewall
ufw allow 'Nginx Full'
ufw allow $PORT_80
ufw allow from $LOCAL_NET to any port $PORT_80
ufw allow $PORT_443
ufw allow from $LOCAL_NET to any port $PORT_443
# Optional additional ports
ufw default deny incoming
ufw default allow outgoing

# Enable ufw
ufw enable
#-----------------------------------------------------------------------------------