#!/bin/bash

while read import; do
	     ${import:+.} "${import:-false}"
	echo ${import:+.} "${import:-false}"
done << IMPORTS
	/etc/lsb-release
	`ls -1              functions*.sh 2> /dev/null`
	`ls -1 ../functions/functions*.sh 2> /dev/null`
IMPORTS

echo WAN
get_nmcli_WAN
echo LAN
get_nmcli_LAN
echo DETAIL
#get_nmcli_detail

#for i in `get_nmcli_WAN` `get_nmcli_LAN`; do
#	echo $i `get_nmcli_detail $i id`
#done



echo uuid
generate_uuid

echo up
nmcli con up uuid `generate_uuid` iface eth0 --nowait

exit 0

echo 0123456789ABCDEF | word_split 2

exit 0

[ -z "${delimiter}" ] && delimiter=' '
    word='0  123456789ABCDEF'
  length=${#word}
  divide=7
remander=$(( length % divide ))

if [[ "$divide" =~ ^- ]]; then
	   divide=${divide:1}
	    start=$remander
	beginning="\${word:0:$remander}"
	unset end
else
	    start=0
	unset beginning
	      end="\${word:$(( length - remander )):$remander}"
fi

  finish=$(( length - divide ))

middle=`seq $start $divide $finish | awk -v div=$divide '{print "${word:"$0":"div"}"}'`
middle=${middle//$'\n'/$delimiter}

eval_str+=${beginning}
eval_str+=${beginning+$delimiter}
eval_str+=${middle}
eval_str+=${end+$delimiter}
eval_str+=${end}

eval echo \"xxx"${eval_str}"xxx\"
#eval echo \"xxx${beginning}"${beginning+$delimiter}"${eval_str}"${end+$delimiter}"${end}xxx\"

exit 0

ip='192.168.1.1'
range='10'
range=`echo "ibase=10;obase=2;$range" | bc`

echo $range

bin=`echo "ibase=10;obase=2;${ip//./;}" | bc | awk '{printf "%08.0f", $0}'`

echo $bin

#bin=`echo "ibase=2;obase=2;$bin + $range" | bc | awk '{printf "%032.0f", $0}'`
bin=`echo "ibase=2;obase=2;$bin + $range" | bc`

echo $bin
D=${bin: -8}
bin=${bin:0:${#bin}-8}
C=${bin: -8}
bin=${bin:0:${#bin}-8}
B=${bin: -8}
A=${bin:0:${#bin}-8}



split=8


exit 0

#get_users_all
#get_user_details root
get_user_details sys
get_user_details 1000
get_user_details all
echo ----------------------------------------

for iface in `get_nmcli_WAN`; do
	echo ----------------------------------------${iface}
	get_nmcli_detail $iface mac
	get_nmcli_detail $iface uuid
	get_nmcli_detail $iface dhcp_ip
	get_nmcli_detail $iface dhcp_mask
	get_nmcli_detail $iface product
	get_nmcli_detail $iface driver
done

for iface in `get_nmcli_LAN`; do
	echo ----------------------------------------${iface}
	get_nmcli_detail $iface mac
	get_nmcli_detail $iface uuid
	get_nmcli_detail $iface ip
	get_nmcli_detail $iface cidr
	get_nmcli_detail $iface gw
	get_nmcli_detail $iface mask
	get_nmcli_detail $iface product
	get_nmcli_detail $iface driver
done

echo ----------------------------------------

#set_nmcli_static eth0 192.168.1.1 24    # Worked
get_dhcpd_subnet_entry eth0
get_dhcpd_subnet_entry eth1
get_dhcpd_subnet_entry eth2














