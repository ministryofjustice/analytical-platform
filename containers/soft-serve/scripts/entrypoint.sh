#!/bin/bash

# Generate an ssh key for use as the admin user. This is needed to run the add-repo-mirrors.sh
# script as the 'admin' user on soft serve

ssh-keygen -t rsa -N "" -f "/home/softserve/.ssh/id_rsa" -C "softserve-admin@localhost"
export SOFT_SERVE_INITIAL_ADMIN_KEYS=$(echo "$(cat /home/softserve/.ssh/id_rsa.pub)")
env | grep INIT

soft serve &
sleep 10

./scripts/add-repo-mirrors.sh

sleep infinity