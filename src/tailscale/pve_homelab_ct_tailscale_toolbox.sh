#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_unifi-controller_toolbox.sh
# Description:  Toolbox script for CT
# Shout Out:    https://glennr.nl/
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------
#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites
#---- Run toolbox component

# Run Glennr UniFi easy update script
pct exec $CTID -- bash -c "rm unifi-update.sh &> /dev/null; wget https://get.glennr.nl/unifi/update/unifi-update.sh && bash unifi-update.sh --skip"

#---- Finish Line ------------------------------------------------------------------