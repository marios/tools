#!/bin/bash

sudo ip route add 10.0.0.0/24 via 192.0.2.1 dev br-ctlplane || true

sudo sed -i 's/^#num_engine_workers.*$/num_engine_workers = 4/g' /etc/heat/heat.conf

sudo systemctl restart openstack-heat-engine

echo "   DnsServers: [\"192.168.122.1\"]" >> network_env.yaml

echo "add some swap to undercloud"
sudo dd if=/dev/zero of=/swapfile count=4k bs=1M
sudo mkswap /swapfile
sudo chmod 0600 /swapfile
sudo swapon /swapfile
cat /proc/swaps

deploy_cmd="openstack overcloud deploy --templates --control-scale 3 --compute-scale 1 --libvirt-type qemu -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/net-single-nic-with-vlans.yaml -e network_env.yaml --ntp-server '0.fedora.pool.ntp.org'"

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
