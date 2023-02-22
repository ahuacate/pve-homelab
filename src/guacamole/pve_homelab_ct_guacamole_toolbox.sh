#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_guacamole_toolbox.sh
# Description:  Toolbox script for CT
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------
#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Run toolbox component
section "Select a Guacamole toolbox option"
OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE02" "TYPE03" "TYPE00" )
OPTIONS_LABELS_INPUT=( "Upgrade Guacamole application" \
"Install Guacamole TOTP $(if [ $(bash -c '[ -f /etc/guacamole/extensions/guacamole-auth-totp*.jar ]; echo $?') = 0 ]; then echo "( installed & active )"; fi)" \
"Install Guacamole Duo $(if [ $(bash -c '[ -f /etc/guacamole/extensions/guacamole-auth-duo*.jar ]; echo $?') = 0 ]; then echo "( installed & active )"; fi)" \
"None. Exit this installer" )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"

if [ "$RESULTS" = 'TYPE01' ]; then
  #---- Upgrade Guacamole tools
  pct push $CTID $SRC_DIR/$APP_BUILD/guacamole_upgrade_sw.sh /tmp/guacamole_upgrade_sw.sh
  pct exec $CTID -- bash -c "/tmp/guacamole_upgrade_sw.sh"
elif [ "$RESULTS" = 'TYPE02' ]; then
  #---- Create Guacamole TOTP
  pct push $CTID $SRC_DIR/$APP_BUILD/guacamole_totp_sw.sh /tmp/guacamole_totp_sw.sh
  pct exec $CTID -- bash -c "/tmp/guacamole_totp_sw.sh"
elif [ "$RESULTS" = 'TYPE03' ]; then
  #---- Create Guacamole Duo
  pct push $CTID $SRC_DIR/$APP_BUILD/guacamole_duo_sw.sh /tmp/guacamole_duo_sw.sh
  pct exec $CTID -- bash -c "/tmp/guacamole_duo_sw.sh"
elif [ "$RESULTS" = 'TYPE00' ]; then
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