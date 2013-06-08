#!/bin/bash
scriptName="$(basename $BASH_SOURCE)"
scriptPath="$(cd `dirname  $BASH_SOURCE`; pwd)"

username=$(who -u | grep "(:0)" | cut -f1 -d" ")
userhome="$(cat /etc/passwd | grep $username | cut -f6 -d:)"

disk=$1

set -x
xhost local:${username}
export DISPLAY=:0.0

rm -f "${userhome}/.VirtualBox/udev.${disk}.\*.vmdk"

su $username -c "VBoxManage controlvm    \$(VBoxManage list vms | grep ${disk} | sed 's/^.//;s/. .*//') poweroff"

sleep 5

su $username -c "VBoxManage unregistervm \$(VBoxManage list vms | grep ${disk} | sed 's/^.//;s/. .*//') --delete"

echo "Goodbye World --- $disk @ $username --- $(date)" >> /root/.custApps/udev.out
