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

# newton and swift node
#deploy_cmd="openstack overcloud deploy --templates $THT_ROOT -e $THT_ROOT/environments/puppet-pacemaker.yaml  --control-scale 3 --compute-scale 1 --libvirt-type qemu --swift-storage-scale 1 -e $THT_ROOT/environments/network-isolation.yaml -e $THT_ROOT/environments/net-single-nic-with-vlans.yaml -e network_env.yaml --ntp-server '0.fedora.pool.ntp.org'"

if ! [[ -e network_env.yaml ]]; then
    echo "writing network_env.yaml, didn't exist:"

cat > network_env.yaml <<ENDOFCAT
parameter_defaults:
  ControlPlaneSubnetCidr: "24"
  ControlPlaneDefaultRoute: 192.0.2.1
  EC2MetadataIp:  192.0.2.1
  DnsServers: ["192.168.122.1"]

ENDOFCAT

fi

vlan10file=/etc/sysconfig/network-scripts/ifcfg-vlan10
if ! [[ -e $vlan10file  ]]; then
    echo "no vlan10 iface defining"
cat > temp_vlan10file <<ENDOFCAT
DEVICE=vlan10
ONBOOT=yes
HOTPLUG=no
TYPE=OVSIntPort
OVS_BRIDGE=br-ctlplane
OVS_OPTIONS="tag=10"
BOOTPROTO=static
IPADDR=10.0.0.1
PREFIX=24
NM_CONTROLLED=no

ENDOFCAT

sudo mv temp_vlan10file $vlan10file
sudo ifup vlan10
fi

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
alias pingtest=" if ! [[ -d ~/tripleo-ci ]]; then git clone http://github.com/openstack-infra/tripleo-ci.git ~/tripleo-ci ;fi; ~/tripleo-ci/scripts/tripleo.sh --overcloud-pingtest"
echo "aliased pingtest "

