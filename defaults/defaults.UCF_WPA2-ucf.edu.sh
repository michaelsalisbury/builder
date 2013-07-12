#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/defaults/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName

function includes(){
	functions.*.sh
	../functions/functions.*.sh
}

# GLOBAL VARIABLES
#function global_variables(){
#	echo
#}

function setup_make_Config(){
	desc Setting up default config
	local scriptBase=$(basename "${scriptName}" .sh)
	# import UCF certificate
	local caPath='/usr/share/ca-certificates/ucf.edu'
	local caFile='UCF-WPA2_comodo_incommonca.crt'
	mkdir -p "${caPath}"
        cp "${scriptPath}/${scriptBase}.crt" "${caPath}/${caFile}"

	# intigrate UCF certificate
	echo $(basename "${caPath}")/${caFile} >> /etc/ca-certificates.conf
	/usr/sbin/update-ca-certificates --fresh

	# test for wireless adapter
	if ! nm-tool | egrep -q "Type:[[:space:]]*802.11"; then
		echo ERROR\! No Wireless Adapter Found.  Not setting up NetworkManager wireless profile for UCF_WPA2.
		return 0
	fi
	
	# get local wifi apater mac address
	local MAC=$(nm-tool |\
		awk '/Type:[[:space:]]*802.11/,/HW Address/{if($0~"HW Address")print $3}')
        	
	# setup connection profile
	cat << END-OF-SYSTEM-CONNECTION > /etc/NetworkManager/system-connections/UCF_WPA2
[ipv6]
method=ignore

[connection]
id=UCF_WPA2
uuid=$(uuidgen)
type=802-11-wireless
timestamp=$(date "+%s")

[802-11-wireless-security]
key-mgmt=wpa-eap

[802-11-wireless]
ssid=UCF_WPA2
mode=infrastructure
mac-address=${MAC}
security=802-11-wireless-security

[802-1x]
eap=peap;
identity=
ca-cert=${caPath}
phase2-auth=mschapv2
password=

[ipv4]
method=auto
END-OF-SYSTEM-CONNECTION
}
