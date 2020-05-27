#!/bin/sh
cd /srv/elderberrypi
export ANSIBLE_LOCAL_TEMP=/tmp/ansible
ansible-playbook playbook.yml --vault-password-file password.file -i hosts 2>&1 | tee -a log
