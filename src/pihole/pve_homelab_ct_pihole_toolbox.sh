#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_pihole_toolbox.sh
# Description:  Toolbox script for CT
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------
#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites
#---- Run toolbox component
section "Select a Pi-Hole toolbox option"
OPTIONS_VALUES_INPUT=( "TYPE01" "TYPE00" )
OPTIONS_LABELS_INPUT=( "Upgrade Pi-Hole application" \
"None. Exit this installer" )
makeselect_input2
singleselect SELECTED "$OPTIONS_STRING"

if [ "$RESULTS" = 'TYPE01' ]
then
  #---- Upgrade Pi-Hole tools
  pct push $CTID $SRC_DIR/$APP_BUILD/pihole_upgrade_sw.sh /tmp/pihole_upgrade_sw.sh
  pct exec $CTID -- bash -c "/tmp/pihole_upgrade_sw.sh"
elif [ "$RESULTS" = 'TYPE00' ]
then
  # Exit installation
  msg "You have chosen not to proceed. Aborting. Bye..."
  echo
  sleep 1
fi

#---- Finish Line ------------------------------------------------------------------

section "Completion Status"

msg "Success. Task complete."
echo

#---- Cleanup
# Clean up CT tmp files
pct exec $CTID -- bash -c "rm -R /tmp/$GIT_REPO &> /dev/null; rm /tmp/${GIT_REPO}.tar.gz &> /dev/null"
#-----------------------------------------------------------------------------------