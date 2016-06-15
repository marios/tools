#!/bin/bash

THT_ROOT=/usr/share/openstack-tripleo-heat-templates
#THT_ROOT=/home/stack/tripleo-heat-templates/

#add some swap
if [[ -z $(cat /proc/swaps | grep -v Filename) ]]; then
  sudo dd if=/dev/zero of=/swapfile count=4k bs=1M
  sudo mkswap /swapfile
  sudo chmod 0600 /swapfile
  sudo swapon /swapfile
  cat /proc/swaps
fi

deploy_cmd="openstack overcloud deploy --templates $THT_ROOT -e $THT_ROOT/overcloud-resource-registry-puppet.yaml -e $THT_ROOT/environments/puppet-pacemaker.yaml  --control-scale 3 --compute-scale 1 --libvirt-type qemu -e $THT_ROOT/environments/network-isolation.yaml -e $THT_ROOT/environments/net-single-nic-with-vlans.yaml -e network_env.yaml --ntp-server '0.fedora.pool.ntp.org'"

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

