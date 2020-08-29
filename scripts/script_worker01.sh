#!/bin/bash
cat >> /etc/hosts <<EOF
192.168.30.2 k8s-lb
192.168.30.5 k8s-master01 
192.168.30.6 k8s-master02
192.168.30.11 k8s-worker02 
EOF