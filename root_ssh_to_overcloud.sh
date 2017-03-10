#!/bin/bash

echo "">.ssh/known_hosts
nova list|grep ctlplane|awk -F' ' '{ print $12 }'|awk -F'=' '{ print $2 }'
overcloud_ips=$(nova list|grep ctlplane|awk -F' ' '{ print $12 }'|awk -F'=' '{ print $2 }')
pubkey=$(sudo cat /root/.ssh/id_rsa.pub)
for i in ${overcloud_ips[@]}; do ssh -o StrictHostKeyChecking=no heat-admin@$i "hostname; echo ''; echo $pubkey >> ~/.ssh/authorized_keys; echo '';"; done;
