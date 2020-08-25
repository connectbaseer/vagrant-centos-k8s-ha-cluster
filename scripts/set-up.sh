#!/bin/bash
set -e
IF_NAME=$1
ADDRESS="$(ip addr show $IF_NAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
sudo sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts
echo "nameserver 8.8.8.8" >> /etc/resolv.conf