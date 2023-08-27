#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_guacamole_toolbox.sh
# Description:  Toolbox script for CT
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

# Repo package name
REPO_PKG_NAME='guacamole'

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Pushing scripts to CT
pct push $CTID $REPO_TEMP/${GIT_REPO}.tar.gz /tmp/${GIT_REPO}.tar.gz
pct exec $CTID -- tar -zxf /tmp/${GIT_REPO}.tar.gz -C /tmp

#---- Run toolbox component

section "Select a Guacamole toolbox option"
OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" "TYPE03" "TYPE03" "TYPE00" )
OPTIONS_LABELS_INPUT=( "Upgrade Guacamole application" \
"Guacamole tune-up (reduce memory usage)" \
"Install Guacamole TOTP $(if [ "$(pct exec $CTID -- bash -c '[[ -f /etc/guacamole/extensions/guacamole-auth-totp*.jar ]]; echo $?')" = 0 ]; then echo "( installed & active )"; fi)" \
"Install Guacamole Duo $(if [ "$(pct exec $CTID -- bash -c '[[ -f /etc/guacamole/extensions/guacamole-auth-duo*.jar ]]; echo $?')" = 0 ]; then echo "( installed & active )"; fi)" \
"None. Exit this installer" )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"

if [ "$RESULTS" = 'TYPE01' ]
then
  #---- Upgrade Guacamole tools
  pct exec $CTID -- bash -c "/tmp/$GIT_REPO/src/$REPO_PKG_NAME/config/guacamole_upgrade_sw.sh"
elif [ "$RESULTS" = 'TYPE02' ]
then
  #---- Guacamole tune-up
  pct exec $CTID -- bash -c "/tmp/$GIT_REPO/src/$REPO_PKG_NAME/config/guacamole_tuneup.sh"
elif [ "$RESULTS" = 'TYPE03' ]
then
  #---- Create Guacamole TOTP
  pct exec $CTID -- bash -c "/tmp/$GIT_REPO/src/$REPO_PKG_NAME/config/guacamole_totp_sw.sh"
elif [ "$RESULTS" = 'TYPE04' ]
then
  #---- Create Guacamole Duo
  pct exec $CTID -- bash -c "/tmp/$GIT_REPO/src/$REPO_PKG_NAME/config/guacamole_duo_sw.sh"
elif [ "$RESULTS" = 'TYPE00' ]
then
  # Exit installation
  msg "You have chosen not to proceed. Aborting. Bye..."
  echo
  sleep 1
fi

#---- Finish Line ------------------------------------------------------------------

section "Completion Status."

msg "Success. Task complete."
echo

#---- Cleanup
# Clean up CT tmp files
pct exec $CTID -- bash -c "rm -R /tmp/$GIT_REPO &> /dev/null; rm /tmp/${GIT_REPO}.tar.gz &> /dev/null"
#-----------------------------------------------------------------------------------