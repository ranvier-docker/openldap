#!/bin/bash

info(){
  echo -e "\033[1;34mINFO\033[0m   $1"
}

warn(){
  echo -e "\033[0;33mWARN\033[0m   $1"
}

fatal(){
  echo -e "\033[0;31mFATAL\033[0m  $1"
  exit 1
}

start_ldap(){
  slapd -F /config/slapd.d -u openldap -g openldap -h 'ldap:// ldaps:// ldapi:///' $@
}
