#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

while read import; do
	. "${import}"
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)


function setup_make_Config(){
	desc Setting up default config
	local scriptBase=$(basename "${scriptName}" .sh)
	# get UCF certificate
	local caPath='/usr/share/ca-certificates/ucf.edu/UCF-WPA2_comodo_incommonca.crt'
        cp "${scriptPath}/${scriptBase}.crt" "${caPath}"
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
function setup_distribute_Config(){
	desc setting up default config \for existing users
	local scriptBase=$(basename "${scriptName}" .sh)
	get_user_details all | while read user uid gid home; do
		usermod -a -G cifs ${user}
		su -m ${user} < <(cat << END-OF-CMDS
			mkdir -p  "${home}/.scripts
			chmod 750 "${home}/.scripts
			mkdir -p  "${home}/.logs
			chmod 750 "${home}/.logs
			cp "/etc/skel/.scripts/mount.domain_cifs.sh" "${home}/.scripts/.
			chmod 750                                    "${home}/.scripts/mount.domain_cifs.sh"
			cp "/etc/skel/.cifs-*"                       "${home}/."
			chmod 600                                    "${home}/.cifs-*
END-OF-CMDS
)
	done
}

