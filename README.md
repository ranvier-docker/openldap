
# OpenLDAP Docker Image

## About

The purpose of this project is to create a containerized and scalable OpenLDAP image for use in various
development projects and/or production environments. It is intended to be as noninteractive as possible
and makes full use of environment variables for configuration.

## Quickstart

1. Run `docker-compose up -d` (make sure you modify the configuration variables first!)

2. Login to your LDAP server w/ username `cn=admin,dc=example,dc=com` and whatever password you chose

## Development

### Initalization

This container has been set up with two possible states in mind: `configured` and `unconfigured`. The first time that you start a container, it will be **unconfigured**. This means you will have to set some environment variables as well as follow an interactive prompt that will appear when run for the first time. An example of what an initializing Docker command might be:

```bash
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
```

After running this, you might then run the following for a persistent server:

```bash
docker run -dit \
--restart=always \
--name openldap \
-v /srv/ldap/config:/config \
-v /srv/ldap/db:/var/lib/ldap \
ranvier/openldap:prod
```

\* *Note the lack of environment variables*

### Environment Variables

When configuring a server for the first time, whether as a master or a slave, a certain set of environment variables are required:

- `ORG_NAME`    : Organization's name. e.g. `Ranvier`
- `ORG_DNS`     : Organization's distinguished name. e.g. `example.com`
- `ORG_DN`      : Organization's distinguished name. e.g. `dc=example,dc=com`
- `SERVER_FQDN` : Fully qualified domain name of the server. e.g. `ldap.example.com`
- `ROOT_SECRET` : Password for the default admin user in LDAP

These currently don't do much, but hopefully they will in the future.

### TLS

When the server is configured for the first time, it is configured to look for the following files:

- `/config/certs/ca-certificates.crt` : List of CA certificates
- `/config/certs/server.crt`          : The server's certificate
- `/config/certs/server.key`          : The server's key

These are generated on initial configuration but it is also possible to drop in your own key and certificate by simply replacing these files.

### Authorization

The default admin account to the server has a DN of `cn=admin,ORG_DN` where ORG_DN is the base DN that was specified at initialization of the container. Likewise, the password for this user is the same as the ROOT_SECRET that was specified at initalization.

e.g. `cn=admin,dc=example,dc=com`

## Configuring and Using OpenLDAP

### ldap-utils

### Searching a Server

```bash
ldapsearch -H ldaps://ds1-dev.example.com -b dc=example,dc=com -D cn=admin,dc=example,dc=com -W <filter> <attrs>
```

### Modifying DIT Information (with LDIF)

```bash
ldapmodify -H ldaps://ds1-dev.example.com -D cn=admin,dc=example,dc=com -W -f dit-changes.ldif
```

### Modifying Server Configuration (OLC) (with LDIF)

To modify locally / within container

```bash
docker exec -it openldap bash
ldapmodify -Y EXTERNAL -H ldapi:/// -f config-changes.ldif
```

To modify remotely (**cn=admin,cn=config user must exist!**)

```bash
ldapmodify -H ldaps://ds1-dev.example.com -D cn=admin,cn=config -W -f config-changes.ldif
```

### Ignoring Invalid TLS Certificates (for self-signed deployments)

`export LDAPTLS_REQCERT=never` or `LDAPTLS_REQCERT=never ldapsearch ...`

## To-Do

- [x] Remove interactive configuration wizard in favor of automatic configuration based on environment variables.
  - [x] Add cn=admin,cn=config user (with same pass as default admin) for configuration management.
  - [ ] On configured containers, confirm all schemas in the resources folder are applied.
- [ ] Consider using Alpine
- [ ] Add documentation for general use cases
- [ ] Upload to Docker Hub

## Notes

- slapd.conf / ldap.conf are deprecated as configuration options. See more details [here](https://www.zytrax.com/books/ldap/ch6/slapd-config.html).

## Resources

- [Offical Ubuntu documentation for OpenLDAP](https://help.ubuntu.com/lts/serverguide/openldap-server.html)
- [Additional slapd configuration](https://www.zytrax.com/books/ldap/ch6/slapd-config.html)
- [Adding an admin user to the cn=config database](https://gos.si/blog/installing-openldap-on-debian-squeeze-with-olc/) [(Source 2)](https://www.zytrax.com/books/ldap/ch6/slapd-config.html)
- [Securing LDAP](https://www.zytrax.com/books/ldap/ch5/step2.html#step2)
- [Mandatory TLS](https://serverfault.com/questions/459718/configure-openldap-with-tls-required)
- [LDAP Replication (Ubuntu Server Guide)](https://ubuntu.com/server/docs/service-ldap-replication)
- [ldap-utils Guide](https://www.digitalocean.com/community/tutorials/how-to-configure-openldap-and-perform-administrative-ldap-tasks)
