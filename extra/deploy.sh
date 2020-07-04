#!/bin/bash

###################################################################
# Quickstart script for deploying an OpenLDAP server using Docker #
###################################################################

# Configuration
DEPLOY_DIR=$PWD
SERVER_FQDN='ldap.example.com'

# Prompt user to make sure they've made modifications
echo 'WARN   Please review this script and ensure you have made all necessary changes'
printf 'Press enter to continue...'
read

# Build the latest image
# docker build -t ranvier/openldap:latest openldap/

# Configure the server if not already configured
if [[ ! -f $DEPLOY_DIR/data/config/.configured.flag  ]]; then
  docker run -it --rm \
  --name openldap-init \
  -v $DEPLOY_DIR/data/db:/var/lib/ldap \
  -v $DEPLOY_DIR/data/config:/config \
  -e ORG_NAME="Ranvier" \
  -e ORG_DNS="example.com" \
  -e ORG_DN="dc=example,com" \
  -e SERVER_FQDN=$SERVER_FQDN \
  -e ROOT_SECRET="password" \
  ranvier/openldap:latest
fi

# Run the server (persistently)
docker run -dit --restart=always \
  --name openldap \
  -v $DEPLOY_DIR/data/db:/var/lib/ldap \
  -v $DEPLOY_DIR/data/config:/config \
  -p 389:389 \
  -p 636:636 \
  ranvier/openldap:latest

echo "INFO   Deployment complete! Check out your server @ ldaps://$HOSTNAME"

exit 0
