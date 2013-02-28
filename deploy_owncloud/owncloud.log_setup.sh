#!/bin/bash

yum -y install incron

cat << END-OF-CONFIG >> /etc/incron.d/owncloud.conf
/tmp IN_CLOSE_WRITE /bin/bash /etc/owncloud/owncloud.log.sh $@/$# $%
END-OF-CONFIG

chkconfig incrond on
service incrond restart

cat /etc/incron.d/owncloud.conf

