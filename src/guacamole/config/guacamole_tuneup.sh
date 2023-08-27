#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     guacamole_tuneup.sh
# Description:  Source script for CT SW
#               This script is for tuning the performance of Guacamole and MySQL
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )
COMMON="$DIR/../../../common"
SHARED="$DIR/../../../shared"

#---- Dependencies -----------------------------------------------------------------

# # Check for Crudini installation
# if [[ ! $(dpkg -s crudini 2> /dev/null) ]]
# then
#   apt-get install -y crudini > /dev/null
# fi

#---- Static Variables -------------------------------------------------------------

# Tune JAVA via systemd unit
# Set the memory value
java_mem=512
java_mem_heap=1

#---- Other Variables --------------------------------------------------------------

# Get Tomcat Version
TOMCAT=$(ls /etc/ | grep tomcat)


#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Run Bash Header
source $COMMON/bash/src/basic_bash_utility.sh


# Stop services
pct_stop_systemctl "$TOMCAT"
pct_stop_systemctl "guacd"
pct_stop_systemctl "mysql.service"

#---- Tune Guacamole mysqld

# Set 'mysql' variables to reduce memory usage
# These settings are for basic home Guacamole setup to enable remote access etc
# This action replaces the file '/etc/mysql/my.cnf'
cat <<EOF > /etc/mysql/my.cnf
#
# The MySQL database server configuration file.
#
# You can copy this to one of:
# - "/etc/mysql/my.cnf" to set global options,
# - "~/.my.cnf" to set user-specific options.
#
# One can use all long options that the program supports.
# Run program with --help to get a list of available options and with
# --print-defaults to see which it would actually understand and use.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

#
# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#

!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/

[mysqld]
#
# * Fine Tuning
#
performance_schema = off
key_buffer_size = 8M
tmp_table_size = 1M
innodb_buffer_pool_size = 1M
innodb_log_buffer_size = 1M
max_connections = 5
sort_buffer_size = 512K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
join_buffer_size = 128K
thread_stack = 196K
binlog_cache_size = 0M
EOF


#---- Tune JAVA via systemd unit

# Define the unit file path
unit_file="/lib/systemd/system/${TOMCAT}.service"

# Check if the Environment line for CATALINA_OPTS exists
if grep -q '^Environment="CATALINA_OPTS=-Xmx[0-9]*m"$' "$unit_file"; then
    # Replace the memory value in the existing line
    sed -i '/^Environment="CATALINA_OPTS=-Xmx[0-9]*m"$/c\Environment="CATALINA_OPTS=-Xmx'"$java_mem"'m"' "$unit_file"
else
    # Add the missing Environment line for CATALINA_OPTS
    sed -i '/\[Service\]/a Environment="CATALINA_OPTS=-Xmx'"$java_mem"'m"' "$unit_file"
fi

# Check if the Environment line for UseG1G exists
if grep -q '^Environment="\$CATALINA_OPTS -XX:+UseG[0-9]*G"$' "$unit_file"; then
    # Replace the memory value in the existing line
    sed -i '/^Environment="\$CATALINA_OPTS -XX:+UseG[0-9]*G"$/c\Environment="\$CATALINA_OPTS -XX:+UseG'"$java_mem_heap"'G"' "$unit_file"
else
    # Add the missing Environment line for UseG1G
    sed -i '/\[Service\]/a Environment="\$CATALINA_OPTS -XX:+UseG'"$java_mem_heap"'G"' "$unit_file"
fi

# Reload the systemd daemon to apply the changes 
sudo systemctl daemon-reload


# Restart services
pct_start_systemctl "mysql.service"
pct_start_systemctl "$TOMCAT"
pct_start_systemctl "guacd"
#-----------------------------------------------------------------------------------