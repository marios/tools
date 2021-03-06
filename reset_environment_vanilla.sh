#!/bin/bash

directory=$1
if [[ -z $directory ]]; then
        echo "gimme the root dir"
        ls -l /home/
        exit 1
fi
echo "ARE YOU SURE!?"
read sure
if [[ $sure != "awoo" ]]; then
  exit 0
fi
echo "deleting all vms"
for i in $(virsh list | grep -v "Id" | awk '{print $2}'); do virsh destroy $i; done
virsh list --all
echo "deleting current instack.qcow2 and copying image from $directory"
sudo rm -rfv /var/lib/libvirt/images/instack.qcow2
sudo cp -v /home/$directory/instack.qcow2 /var/lib/libvirt/images/instack.qcow2
echo "starting the undercloud"
virsh start instack
virsh list

echo "sleeping for a bit cos we want ssh on the new undercloud"
sleep 30

echo "copy the overcloud deploy script to the new undercloud"

undercloud_ip=$(virsh domifaddr instack | grep 192.168 | awk '{print $4}' | sed 's/\/.*$//g')
# refresh the overcloud.sh script:
rm -rf deploy_overcloud.sh
curl -O "https://raw.githubusercontent.com/marios/tools/master/deploy_overcloud.sh"
scp deploy_overcloud.sh root@$undercloud_ip:/home/stack/
ssh root@$undercloud_ip "chown stack:stack /home/stack/deploy_overcloud.sh; chmod 754 /home/stack/deploy_overcloud.sh"
echo "undercloud is at $undercloud_ip - ssh root@$undercloud_ip"

