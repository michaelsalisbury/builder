#!/bin/bash
scriptName="$(basename $BASH_SOURCE)"
scriptPath="$(cd `dirname  $BASH_SOURCE`; pwd)"

username=$(who -u | grep "(:0)" | cut -f1 -d" ")
userhome="$(cat /etc/passwd | grep $username | cut -f6 -d:)"

#set -x
#xhost local:${username}
#export DISPLAY=:0.0

#disk=sdf
disk=$1
vrdeport=33890
vrdeport=$(( 33890 + $(printf "%d\n" \'${disk:2}) - 99 ))
name=myVM
name="${name}-${vrdeport}"
vmdk="${userhome}/.VirtualBox/udev.${disk}.${name}.vmdk"


#iso=/home/localcosadmin/ISO/SpinRite.iso
iso=$2
sctl=ide


rm ${vmdk}
sudo VBoxManage internalcommands createrawvmdk -filename "${vmdk}" -rawdisk /dev/${disk}
sudo chmod a+rw ${vmdk}
sudo chown $username.vboxusers ${vmdk}
sudo chmod a+rw /dev/${disk}
sudo chown $username.vboxusers /dev/${disk}


VBoxManage controlvm ${name}.${disk} poweroff
sleep 5
VBoxManage unregistervm	   ${name}.${disk} --delete
VBoxManage createvm --name ${name}.${disk} --ostype Other --register
VBoxManage modifyvm        ${name}.${disk} --memory 256


VBoxManage modifyvm        ${name}.${disk} --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm        ${name}.${disk} --boot1 dvd --boot2 net --boot3 disk --boot4 none
VBoxManage modifyvm        ${name}.${disk} --nic1 bridged --cableconnected1 on --bridgeadapter1 eth0
VBoxManage modifyvm        ${name}.${disk} --vrde on --vrdeport ${vrdeport} --vrdeauthtype null --vrdemulticon on



VBoxManage storagectl      ${name}.${disk} --name ${sctl} --add ${sctl} --bootable on
VBoxManage storageattach   ${name}.${disk} --storagectl ${sctl} --port 0 --device 0 --type dvddrive --medium "${iso}"
VBoxManage storageattach   ${name}.${disk} --storagectl ${sctl} --port 1 --device 0 --type hdd --medium "${vmdk}"



VirtualBox --startvm spinrite.${disk}







#VBoxManage showvminfo      spinrite.${disk}
#VBoxManage list vms
