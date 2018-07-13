#!/bin/bash

git clone https://git.openstack.org/openstack/openstack-ansible /opt/openstack-ansible
cd /opt/openstack-ansible
git tag -l
git checkout stable/pike
 
#
#export BOOTSTRAP_OPTS="bootstrap_host_data_disk_device=sdb"
#
time ./scripts/bootstrap-ansible.sh

# Use the Ceph scenario
export SCENARIO='ceph'
export BOOTSTRAP_OPTS='-vv'
time ./scripts/bootstrap-aio.sh

# Add OpenStack services
cd /opt/openstack-ansible/playbooks
cp etc/openstack_deploy/conf.d/{aodh,gnocchi,ceilometer}.yml.aio /etc/openstack_deploy/conf.d/
for f in $(ls -1 /etc/openstack_deploy/conf.d/*.aio); do mv -v ${f} ${f%.*}; done

#
cd /opt/openstack-ansible/playbooks
time openstack-ansible setup-hosts.yml
time openstack-ansible setup-infrastructure.yml

# Check if mysql is installed
ansible galera_container -m shell \
-a "mysql -h localhost -e 'show status like \"%wsrep_cluster_%\";'"

time openstack-ansible setup-openstack.yml

