#!/bin/bash -ex

distro=$1
mkdir precise
mkdir -p $distro

function build {
    sudo apt-get install charm-tools -y
    (cd $distro/charm-$1; charm build -s $distro  -obuild src)
    mv $distro/charm-$1/build/$distro/$1 $distro
}

# openstack
bzr branch lp:~narindergupta/charms/trusty/promise/trunk $distro/promise
charm pull cs:trusty/mongodb $distro/mongodb
charm pull cs:$distro/haproxy $distro/haproxy
charm pull cs:$distro/ntp $distro/ntp
charm pull cs:$distro/aodh $distro/aodh
charm pull cs:~narindergupta/congress-0 $distro/congress

git clone -b stable/17.02 https://github.com/openstack/charm-hacluster.git $distro/hacluster
#bzr branch lp:~sdn-charmers/charms/$distro/ceilometer/ceilometer-plugin $distro/ceilometer
#git clone -b stable/17.02 https://github.com/openstack/charm-ceilometer.git $distro/ceilometer
#git clone -b stable/17.02 https://github.com/openstack/charm-ceilometer-agent.git $distro/ceilometer-agent
git clone -b stable/17.02 https://github.com/openstack/charm-ceph-mon.git $distro/ceph-mon
git clone -b stable/17.02 https://github.com/openstack/charm-ceph-osd.git $distro/ceph-osd
git clone -b stable/17.02 https://github.com/openstack/charm-ceph-radosgw.git $distro/ceph-radosgw
git clone -b stable/17.02 https://github.com/openstack/charm-cinder.git $distro/cinder
git clone -b stable/17.02 https://github.com/openstack/charm-cinder-ceph.git $distro/cinder-ceph
git clone -b stable/17.02 https://github.com/openstack/charm-glance.git $distro/glance
git clone -b stable/17.02 https://github.com/openstack/charm-keystone.git $distro/keystone
git clone -b stable/17.02 https://github.com/openstack/charm-percona-cluster.git $distro/percona-cluster
git clone -b stable/17.02 https://github.com/openstack/charm-neutron-gateway.git $distro/neutron-gateway
#git clone -b stable/17.02 https://github.com/openstack/charm-neutron-openvswitch.git $distro/neutron-openvswitch
git clone -b stable/17.02 https://github.com/openstack/charm-nova-cloud-controller.git $distro/nova-cloud-controller
git clone -b stable/17.02 https://github.com/openstack/charm-nova-compute.git $distro/nova-compute
git clone -b stable/17.02 https://github.com/openstack/charm-openstack-dashboard.git $distro/openstack-dashboard
git clone -b stable/17.02 https://github.com/openstack/charm-rabbitmq-server.git $distro/rabbitmq-server
git clone -b stable/17.02 https://github.com/openstack/charm-heat.git $distro/heat
git clone -b stable/17.02 https://github.com/openstack/charm-neutron-api.git $distro/neutron-api

#pulling scaleio charms.
charm pull cs:~cloudscaling/scaleio-mdm $distro/scaleio-mdm
charm pull cs:~cloudscaling/scaleio-sds $distro/scaleio-sds
charm pull cs:~cloudscaling/scaleio-gw $distro/scaleio-gw
charm pull cs:~cloudscaling/scaleio-sdc $distro/scaleio-sdc
charm pull cs:~cloudscaling/scaleio-openstack $distro/scaleio-openstack
charm pull cs:~cloudscaling/scaleio-cluster $distro/scaleio-cluster
charm pull cs:~cloudscaling/scaleio-gui $distro/scaleio-gui

#charm pull cs:~openstack-charmers-next/hacluster $distro/hacluster
#charm pull cs:~openstack-charmers-next/ceilometer $distro/ceilometer
#charm pull cs:~openstack-charmers-next/ceilometer-agent $distro/ceilometer-agent
#charm pull cs:~openstack-charmers-next/ceph-mon $distro/ceph
#charm pull cs:~openstack-charmers-next/ceph-osd $distro/ceph-osd
#charm pull cs:~openstack-charmers-next/ceph-radosgw $distro/ceph-radosgw
#charm pull cs:~openstack-charmers-next/cinder $distro/cinder
#charm pull cs:~openstack-charmers-next/cinder-ceph $distro/cinder-ceph
#charm pull cs:~openstack-charmers-next/glance $distro/glance
#charm pull cs:~openstack-charmers-next/keystone $distro/keystone
#charm pull cs:~openstack-charmers-next/percona-cluster $distro/percona-cluster
#charm pull cs:~openstack-charmers-next/neutron-api $distro/neutron-api
#charm pull cs:~openstack-charmers-next/neutron-gateway $distro/neutron-gateway
#charm pull cs:~openstack-charmers-next/neutron-openvswitch $distro/neutron-openvswitch
#charm pull cs:~openstack-charmers-next/nova-cloud-controller $distro/nova-cloud-controller
#charm pull cs:~openstack-charmers-next/nova-compute $distro/nova-compute
#charm pull cs:~openstack-charmers-next/openstack-dashboard $distro/openstack-dashboard
#charm pull cs:~openstack-charmers-next/rabbitmq-server $distro/rabbitmq-server
#charm pull cs:~openstack-charmers-next/heat $distro/heat
#charm pull cs:~openstack-charmers-next/lxd xenial/lxd

# Controller specific charm
git clone https://git.opnfv.org/ovno.git
cd ovno/charms/trusty
mv * ../../../$distro/
cd ../../../
rm -rf ovno
