#!/bin/bash

echo -e "
  ___  _                  _                         , __    
 / (_)| |    |           | |                       /|/  \o  
 \__  | |  __|   _   ,_  | |   _   ,_    ,_         |___/   
 /    |/  /  |  |/  /  | |/ \_|/  /  |  /  |  |   | |    |  
 \___/|__/\_/|_/|__/   |_/\_/ |__/   |_/   |_/ \_/|/|    |_/
                                                 /|         
                                                 \|
"

# Handle command line options
RESET_CONFIG=false

while true; do
  case "$1" in
    -r|--reset-config)
      RESET_CONFIG=true
      shift
      ;;
    *)
      break
      ;;
  esac
done

# Check for dependencies
command -v vagrant >/dev/null 2>&1 || { echo -e >&2 "Vagrant is required but it's not installed.  Aborting."; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo -e >&2 "Ansible is required but it's not installed.  Aborting."; exit 1; }

# Create Ansible randomly-generated password file if it does not exist
if [ ! -f ./ansible/password.file ]; then
  echo -e "$(base64 < /dev/urandom | tr -d 'O0Il1+\' | head -c 44)" > ./ansible/password.file
fi

# Create configuration file if it does not exist
if [ ! -f ./ansible/env.yml ] || [ "$RESET_CONFIG" == "true" ]; then
  echo -e "First Time ElderberryPi Setup\n"

  # Roles
  ROLE_AD=false
  ROLE_CA=false
  ROLE_DNS=false
  ROLE_NTP=false
  ROLE_PXE=false
  ROLE_WEB=false

  # Security Features
  ZYMBIT_INSTALLED=false

  echo -e "ElderberryPi Host Configuration"
  echo -e "==============================="
  while read -p "Hostname: " HOSTNAME && [ -z "$HOSTNAME" ]; do :; done
  while read -p "Fully-Qualified Domain Name (do not include hostname): " FQDN && [ -z "$FQDN" ]; do :; done
  read -p "Is there a Zymbit Hardware Security Module installed? (y/N): " ENABLE_ZYMBIT
  if [ "$ENABLE_ZYMBIT" != "${ENABLE_ZYMBIT#[Yy]}" ]; then
    ZYMBIT_INSTALLED=true
  fi

  echo -e "\nIPv4 Network Configuration"
  echo -e "=========================="
  while read -p "Host IP Address: " IP_ADDRESS && [ -z "$IP_ADDRESS" ]; do :; done
  while read -p "Network Address: " NETWORK && [ -z "$NETWORK" ]; do :; done
  while read -p "Subnet Mask in bits: /" CIDR && [ -z "$CIDR" ]; do :; done
  while read -p "Gateway Address: " GATEWAY && [ -z "$GATEWAY" ]; do :; done
  while read -p "Name Servers (delimit with comma): " NAMESERVERS && [ -z "$NAMESERVERS" ]; do :; done

  echo -e "\nRoles Configuration"
  echo -e "==================="
  read -p "Enable Active Directory? (y/N): " ENABLE_AD
  if [ "$ENABLE_AD" != "${ENABLE_AD#[Yy]}" ]; then
    echo -e "Enabling dependent roles NTP DNS"
    ROLE_AD=true
    ROLE_NTP=true
    ROLE_DNS=true

    # NetBIOS Domain Name
    unset NETBIOS
    while [ -z "$NETBIOS" ]; do
      read -p "NetBIOS Domain Name: " NETBIOS
      if [ ${#NETBIOS} -gt 15 ]; then
        echo -e "Error: NetBIOS Domain Names must be 15 characters or less in length."
        unset NETBIOS
      fi
    done
    # NetBIOS domain names should be in all caps
    NETBIOS=$(echo -e "$NETBIOS" | awk '{print toupper($0)}')

    # Domain Administrator Password
    unset AD_ADMIN_PASSWORD
    while [ -z "$AD_ADMIN_PASSWORD" ]; do
      read -s -p "Domain Administrator Password: " AD_ADMIN_PASSWORD
      if [ ${#AD_ADMIN_PASSWORD} -lt 8 ]; then
        echo -e "Error: Domain admin password must be at least 8 characters in length."
        unset AD_ADMIN_PASSWORD
      fi
    done
    AD_ADMIN_PASSWORD=$(echo -e -n $AD_ADMIN_PASSWORD | ansible-vault encrypt_string --vault-password-file ./ansible/password.file --stdin-name "adminpassword")
    echo -e ""
  fi

  read -p "Enable Certificate Authority? (y/N): " ENABLE_CA
  if [ "$ENABLE_CA" != "${ENABLE_CA#[Yy]}" ]; then ROLE_CA=true; fi

  if [ "$ROLE_DNS" != true ]; then
    read -p "Enable DNS Server? (y/N): " ENABLE_DNS
    if [ "$ENABLE_DNS" != "${ENABLE_DNS#[Yy]}" ]; then ROLE_DNS=true; fi
  fi

  if [ "$ROLE_NTP" != true ]; then
    read -p "Enable NTP Server? (y/N): " ENABLE_NTP
    if [ "$ENABLE_NTP" != "${ENABLE_NTP#[Yy]}" ]; then ROLE_NTP=true; fi
  fi

  read -p "Enable PXE Server? (y/N): " ENABLE_PXE
  if [ "$ENABLE_PXE" != "${ENABLE_PXE#[Yy]}" ]; then
    echo -e "Enabling dependent role WEB"
    ROLE_PXE=true
    ROLE_WEB=true
  fi

  if [ "$ROLE_WEB" != true ]; then
    read -p "Enable Web Server? (y/N): " ENABLE_WEB
    if [ "$ENABLE_WEB" != "${ENABLE_WEB#[Yy]}" ]; then ROLE_WEB=true; fi
  fi

  echo -e "\nConfiguration Summary"
  echo -e "====================="
  echo -e "Zymbit Installed: ${ZYMBIT_INSTALLED}"
  ROLES="Enabling roles: "
  if $ROLE_AD; then ROLES+="AD "; fi
  if $ROLE_CA; then ROLES+="CA "; fi
  if $ROLE_DNS; then ROLES+="DNS "; fi
  if $ROLE_NTP; then ROLES+="NTP "; fi
  if $ROLE_PXE; then ROLES+="PXE "; fi
  if $ROLE_WEB; then ROLES+="WEB"; fi
  echo -e "$ROLES"

  echo -e "Hostname: ${HOSTNAME}"
  echo -e "Fully-Qualified Domain Name: ${FQDN}"
  echo -e "Host IP Address: ${IP_ADDRESS}"
  echo -e "Network Address: ${NETWORK}"
  echo -e "CIDR Mask: /${CIDR}"
  echo -e "Nameservers: [${NAMESERVERS}]"

  if $ROLE_AD; then
    echo -e "NetBIOS Domain Name: ${NETBIOS}"
  fi

  echo
  read -p "Write configuration? (y/N): " WRITE_CONFIG
  if [ "$WRITE_CONFIG" != "${WRITE_CONFIG#[Yy]}" ]; then
    # Write Ansible Variables file
    echo -e "---\n\n# System configuration" > ./ansible/env.yml
    echo -e "hostname: '${HOSTNAME}'" >> ./ansible/env.yml
    echo -e "domain: '${FQDN}'" >> ./ansible/env.yml
    echo -e "ip_address: '${IP_ADDRESS}/${CIDR}'" >> ./ansible/env.yml
    echo -e "network: '${NETWORK}/${CIDR}'" >> ./ansible/env.yml
    echo -e "gateway: '${GATEWAY}'" >> ./ansible/env.yml
    echo -e "nameservers: '[${NAMESERVERS}]'" >> ./ansible/env.yml
    if $ROLE_AD; then
      echo -e "\n# Active Directory configuration" >> ./ansible/env.yml
      echo -e "netbios_domain: '${NETBIOS}'" >> ./ansible/env.yml
      echo -e "${AD_ADMIN_PASSWORD}" >> ./ansible/env.yml
    fi

    # Write Ansible Playbook
    # TODO: Is there a way to load roles from separate file so that the basic
    #       playbook elements may be committed to git?
    echo -e "---\n" > ./ansible/playbook.yml
    echo -e "- hosts: localhost" >> ./ansible/playbook.yml
    echo -e "  module_defaults:" >> ./ansible/playbook.yml
    echo -e "    apt:" >> ./ansible/playbook.yml
    echo -e "      force_apt_get: yes" >> ./ansible/playbook.yml
    echo -e "  become: yes" >> ./ansible/playbook.yml
    echo -e "  vars_files:" >> ./ansible/playbook.yml
    echo -e "    - env.yml" >> ./ansible/playbook.yml
    echo -e "  roles:" >> ./ansible/playbook.yml
    echo -e "  - role: common" >> ./ansible/playbook.yml
    if $ZYMBIT_INSTALLED; then echo -e "  - role: zymbit" >> ./ansible/playbook.yml; fi
    if $ROLE_NTP; then echo -e "  - role: ntp" >> ./ansible/playbook.yml; fi
    if $ROLE_DNS; then echo -e "  - role: dns" >> ./ansible/playbook.yml; fi
    if $ROLE_CA;  then echo -e "  - role: ca" >> ./ansible/playbook.yml; fi
    if $ROLE_AD;  then echo -e "  - role: active_directory" >> ./ansible/playbook.yml; fi
    if $ROLE_WEB; then echo -e "  - role: web" >> ./ansible/playbook.yml; fi
    if $ROLE_PXE; then echo -e "  - role: pxe" >> ./ansible/playbook.yml; fi
  fi
else
  echo -e "Found existing configuration. Pass --reset-config if you want to reconfigure."
fi

# Select SSH Key
if [ ! -f ./vagrant/elderberrypi.key.pub ]; then
  echo -e "\nThere is no existing SSH key configured.  Please select an existing key from your user profile or generate a new one:"
  # Pick existing key or generate a new one
  KEYS=$(ls ~/.ssh/*.pub)
  KEYS=($KEYS "Generate new key")
  select key in "${KEYS[@]}"; do
    if [ "$key" == "Generate new key" ]; then
      ssh-keygen -f ./vagrant/elderberrypi.key -t ed25519
      mv ./vagrant/elderberrypi.key ~/.ssh/
      cp ./vagrant/elderberrypi.key.pub ~/.ssh/
      echo "To connect to your ElderberryPi via ssh, run:"
      echo "  ssh -i ~/.ssh/elderberrypi.key ubuntu@${IP_ADDRESS}"
    else
      cp $key ./vagrant/elderberrypi.key.pub
      echo "To connect to your ElderberryPi via ssh, run:"
      printf "  ssh -i %s ubuntu@${IP_ADDRESS}\n" "${key//'.pub'}"
    fi
    break
  done
fi

# Bring up Build Environment
echo -e "\nCreating build environment...\n"
cd vagrant && vagrant up --provision
