#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     addon-updatelists_installer.sh
# Description:  Installer script for PiHole addon
# Thanks:       https://github.com/jacklul/pihole-updatelists
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

#---- Repo variables
# Git server
GIT_SERVER='https://github.com'
# Git user
GIT_USER='ahuacate'
# Git repository
GIT_REPO='pve-homelab'
# Git branch
GIT_BRANCH='main'
# Git common
GIT_COMMON='0'

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Install PiHole Updatelists (Automatic weekly list updater)
# Thanks to https://github.com/jacklul/pihole-updatelists

# Prerequisites
pct exec $CTID -- sudo apt-get install php-cli php-sqlite3 php-intl php-curl -yqq

# Install PiHole-Updatelists
pct exec $CTID -- bash -c 'wget -O - https://raw.githubusercontent.com/jacklul/pihole-updatelists/master/install.sh | sudo bash'

# Disable Gravity update Also after each Pi-hole update)
pct exec $CTID -- sed -e '/pihole updateGravity/ s/^#*/#/' -i /etc/cron.d/pihole


#---- List Source
msg_box "You can choose to use the default lists or the Ahuacate lists. We recommend the default list because in the long term you will likely create your own whitelists.

Default lists are:
  AD LISTS
  --  https://v.firebog.net/hosts/lists.php?type=tick
  --  Ahuacate list ( optional )

  WHITE LISTS
  --  https://raw.githubusercontent.com/anudeepND/whitelist/master/
      domains/whitelist.txt
  --  Ahuacate list ( optional )

  BLACK LISTS
  --  https://raw.githubusercontent.com/mmotti/pihole-regex/
      master/regex.list
  --  Ahuacate list ( optional )"

# Make selection
OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" )
OPTIONS_LABELS_INPUT=( "Default Lists ( Recommended )" "Ahuacate Lists" )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"

if [ ${RESULTS} == TYPE01 ]; then
  # Default configuration file is /etc/pihole-updatelists.conf
  # my_adlists
  pct exec $CTID -- sed -i "s|^ADLISTS_URL=.*|ADLISTS_URL=\"https://v.firebog.net/hosts/lists.php?type=tick\"|" /etc/pihole-updatelists.conf
  # my_whitelist_url
  pct exec $CTID -- sed -i "s|^WHITELIST_URL=.*|WHITELIST_URL=\"https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt\"|" /etc/pihole-updatelists.conf
  # my_regex_blacklist_url
  pct exec $CTID -- sed -i "s|^REGEX_BLACKLIST_URL=.*|REGEX_BLACKLIST_URL=\"https://raw.githubusercontent.com/mmotti/pihole-regex/master/regex.list\"|" /etc/pihole-updatelists.conf
elif [ ${RESULTS} == TYPE02 ]; then
  # Default configuration file is /etc/pihole-updatelists.conf
  # SRC Url
  MY_LIST_SRC="https://raw.githubusercontent.com/${GIT_USER}/${GIT_REPO}/main/src/pihole/source/config"
  # my_adlists
  pct exec $CTID -- sed -i "s|^ADLISTS_URL=.*|ADLISTS_URL=\"https://v.firebog.net/hosts/lists.php?type=tick ${MY_LIST_SRC}/my_adlists.txt\"|" /etc/pihole-updatelists.conf
  # my_whitelist_url
  pct exec $CTID -- sed -i "s|^WHITELIST_URL=.*|WHITELIST_URL=\"${MY_LIST_SRC}/my_whitelist_url.txt https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt\"|" /etc/pihole-updatelists.conf
  # my_regex_whitelist_url
  pct exec $CTID -- sed -i "s|^REGEX_WHITELIST_URL=.*|REGEX_WHITELIST_URL=\"${MY_LIST_SRC}/my_regex_whitelist_url.txt\"|" /etc/pihole-updatelists.conf
  # my_blacklist_url
  pct exec $CTID -- sed -i "s|^BLACKLIST_URL=.*|BLACKLIST_URL=\"${MY_LIST_SRC}/my_blacklist_url.txt\"|" /etc/pihole-updatelists.conf
  # my_regex_blacklist_url
  pct exec $CTID -- sed -i "s|^REGEX_BLACKLIST_URL=.*|REGEX_BLACKLIST_URL=\"${MY_LIST_SRC}/my_regex_blacklist_url.txt https://raw.githubusercontent.com/mmotti/pihole-regex/master/regex.list\"|" /etc/pihole-updatelists.conf
fi

#--- Update lists
pct exec $CTID -- bash -c 'sudo pihole-updatelists'

#---- Finish Line ------------------------------------------------------------------