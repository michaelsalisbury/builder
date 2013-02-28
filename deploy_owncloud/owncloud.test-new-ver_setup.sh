#!/bin/bash

cat << END-OF-APPEND >> /etc/crontab
0 6 * * * root /bin/bash -l -c /etc/owncloud/owncloud.test-new-ver.sh
END-OF-APPEND

service crond restart

cat /etc/crontab


