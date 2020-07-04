#!/bin/bash
. /app/common.sh

#
# Functions
#

# Requires ORG_NAME, SERVER_URL, CERT_DIR
gen_certs(){

  [[ openssl ]] || fatal "OpenSSL not installed."

  mkdir -p $CERT_DIR || fatal 'Could not create certificate directories'

  # Change into working directory
  cd $CERT_DIR

    # Generate key
    openssl genrsa -out server.key 2048
    openssl rsa -in server.key -out server.key

    # Generate certificate
    openssl req -new -subj '/C=US/ST=New York/L=New York/O=Example Company/CN=example.com' -days 3650 -key server.key -out server.csr
    openssl x509 -days 3650 -in server.csr -out server.crt -req -signkey server.key
    rm server.csr

    cp /etc/ssl/certs/ca-certificates.crt .
    chown -R openldap:openldap *
  
  cd -
}

# Requires ORG_NAME, ORG_DNS, ORG_DN, ROOT_SECRET
gen_init_schema(){

  # Hash password before adding it
  ROOT_HASH=$(slappasswd -s $ROOT_SECRET) || fatal 'Invalid password input!'

  # Initialize configuration
  cat << EOF > /tmp/ldap-init.ldif
# OpenLDAP Initalization
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: $ORG_DN
-
replace: olcRootDN
olcRootDN: cn=admin,$ORG_DN
-
replace: olcRootPW
olcRootPW: $ROOT_HASH

dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootDN
olcRootDN: cn=admin,cn=config
-
add: olcRootPW
olcRootPW: $ROOT_HASH

EOF
  
  # Initialize DIT
  cat << EOF > /tmp/org-init.ldif
# Organization Initalization
dn: $ORG_DN
changetype: add
objectclass: top
objectclass: organization
objectclass: dcObject
o: $ORG_NAME
EOF
}

#
# Main
#

# Variables
[[ -z ${ORG_NAME} ]] && fatal "Environment variable ORG_NAME must be set."
[[ -z ${ORG_DNS} ]] && fatal "Environment variable ORG_DNS must be set."
[[ -z ${ORG_DN} ]] && fatal "Environment variable ORG_DN must be set."
[[ -z ${SERVER_FQDN} ]] && fatal "Environment variable SERVER_FQDN must be set."
[[ -z ${ROOT_SECRET} ]] && fatal "Environment variable ROOT_SECRET must be set."
CERT_DIR='/config/certs'

# Generate certificates
info 'Generating self-signed certificates'
gen_certs && info 'Certificates generated'

# Configure slapd
info 'Initializing LDAP'
dpkg-reconfigure -f noninteractive slapd
gen_init_schema

# Move configuration to persistent location
cp -r /etc/ldap/slapd.d /config/ &&\
chown -R openldap:openldap /config ||\
fatal 'Could not save configuration'

# Apply schemas
start_ldap
sleep 1
LDAP_PID=`pgrep slapd`

info 'Importing LDAP configuration'
ldapmodify -a -Y EXTERNAL -H ldapi:/// -f /tmp/ldap-init.ldif || fatal 'Could not initialize server configuration!'

info 'Importing LDAP organization'
ldapmodify -H ldapi:/// -D cn=admin,$ORG_DN -w $ROOT_SECRET -f /tmp/org-init.ldif || fatal 'Could not create organization!'

info 'Importing schemas'
for schema in /app/schema/*.ldif; do
    info "Applying $schema"
    ldapmodify -a -Y EXTERNAL -H ldapi:/// -f $schema || fatal "Could not apply ${schema}!"
done

sleep 1
kill -s SIGINT $LDAP_PID

# Mark service as configured
touch /config/.configured.flag

# Cleanup
rm -rf /tmp/*
rm -rf /etc/ldap
