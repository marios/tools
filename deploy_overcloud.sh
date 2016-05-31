#!/bin/bash

#add some swap
if [[ -z $(cat /proc/swaps | grep -v Filename) ]]; then
  sudo dd if=/dev/zero of=/swapfile count=4k bs=1M
  sudo mkswap /swapfile
  sudo chmod 0600 /swapfile
  sudo swapon /swapfile
  cat /proc/swaps
fi

deploy_cmd="openstack overcloud deploy --templates /home/stack/tripleo-heat-templates -e /home/stack/tripleo-heat-templates/overcloud-resource-registry-puppet.yaml -e /home/stack/tripleo-heat-templates/environments/puppet-pacemaker.yaml  --control-scale 3 --compute-scale 1 --libvirt-type qemu -e /home/stack/tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/tripleo-heat-templates/environments/net-single-nic-with-vlans.yaml -e network_env.yaml --ntp-server '0.fedora.pool.ntp.org'"

echo "going to deploy like this $deploy_cmd"
echo "network env like"
cat ~/network_env.yaml
echo "OK DEPLOYING - continue?"
read proceed
if [[ $proceed != awoo ]]; then
  exit 0
fi
echo "started $deploy_cmd at `date`" > ~/deploy_time
source ~/stackrc
$deploy_cmd
echo "OK DONE at  `date`" >> ~/deploy_time
