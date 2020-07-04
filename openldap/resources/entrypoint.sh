#!/bin/bash

. /app/common.sh

## Main ##

# Initial Configuration
if [ ! -e /config/.configured.flag ]; then
  /app/configure.sh || fatal 'Could not configure OpenLDAP!'
  
  info 'Server configured!'
fi

# TODO  Ensure saved schemas are applied

# Start OpenLDAP in foreground
info "Starting OpenLDAP"
start_ldap -d 256

exit 0
