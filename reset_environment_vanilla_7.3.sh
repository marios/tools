#!/bin/bash

echo "ARE YOU SURE!?"
read sure
if [[ $sure != "awoo" ]]; then
  exit 0
fi
echo "deleting all vms"
for i in $(virsh list | grep -v "Id" | awk '{print $2}'); do virsh destroy $i; done
virsh list --all
echo "copying images"
sudo rm -rf /home/vm_storage_pool/baremetalbrbm_*
sudo cp /home/VANILLA_UNDERCLOUD/baremetalbrbm_* /home/vm_storage_pool/
sudo rm -rf /var/lib/libvirt/images/instack.qcow2
sudo cp /home/VANILLA_UNDERCLOUD/instack.qcow2.bigger.nodes /var/lib/libvirt/images/instack.qcow2
echo "starting the undercloud"
virsh start instack
virsh list

echo "sleeping for a bit cos we want ssh on the new undercloud"
sleep 30

echo "copy the overcloud deploy script to the new undercloud"

undercloud_ip=$(virsh domifaddr instack | grep 192.168 | awk '{print $4}' | sed 's/\/.*$//g')
scp ~/scripts/deploy_overcloud.sh root@$undercloud_ip:/home/stack/
ssh root@$undercloud_ip "chown stack:stack /home/stack/deploy_overcloud.sh; chmod 754 /home/stack/deploy_overcloud.sh"
echo "undercloud is at $undercloud_ip - ssh root@$undercloud_ip"

