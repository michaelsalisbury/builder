#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

while read import; do
	. "${import}"
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

function setup_skel_Structure(){
	desc Build skel directory structure
	mkdir -p   /etc/skel/.scripts
	chmod 750  /etc/skel/.scripts
	mkdir -p   /etc/skel/.logs
	chmod 750  /etc/skel/.logs
	local scriptBase=$(basename "${scriptName}" .sh)
	cp "${scriptPath}/${scriptBase}.exp" /etc/skel/.scripts/.
	chmod 750 "/etc/skel/.scripts/${scriptBase}.exp"
	touch      /etc/skel/.vpn.conf
	chmod 600  /etc/skel/.vpn.conf
	touch      /etc/sudoers.d/openconnect
	chmod 440  /etc/sudoers.d/openconnect
	groupadd -g 140 openconnect
}
function setup_make_Config(){
	desc Setting up default config
	cat << END-OF-ALIASES > /etc/profile.d/openconnect
alias vpnc='\${HOME}/.scripts/${scriptBase}.exp &> \${HOME}/.logs/${scriptBase} &'
alias vpnd='killall openconnect'
alias vpns='ifconfig tun; tail \${HOME}/.logs/${scriptBase}'
END-OF-ALIASES
	cat << END-OF-VPNCONF >> /etc/skel/.vpn.conf
username = [NID]
password = [***]
group    = [ucffaculty|ucfstudent]
url      = ucfvpn-1.vpn.ucf.edu
END-OF-VPNCONF
	cat << END-OF-SUDOERS > /etc/sudoers.d/openconnect
# openconnect
%openconnect ALL=(root) NOPASSWD:/usr/sbin/openconnect
%openconnect ALL=(root) NOPASSWD:/usr/bin/killall openconnect
END-OF-SUDOERS
	# Modify /etc/addusers.conf to include new group openconnect
	sed -i '/^.*EXTRA_GROUPS=/ s/^[# ]*//'             /etc/addusers.conf
	sed -i '/^EXTRA_GROUPS=/   s/"$/ openconnect"/'    /etc/addusers.conf
	sed -i '/^ADD_EXTRA_GROUPS=.*/cADD_EXTRA_GROUPS=1' /etc/addusers.conf
}
function setup_distribute_Config(){
	desc setting up default config \for existing users
	local scriptBase=$(basename "${scriptName}" .sh)
	get_user_details all | while read user uid gid home; do
		su -m ${user} < <(cat << END-OF-CMDS
			mkdir -p  "${home}/.scripts
			chmod 750 "${home}/.scripts
			mkdir -p  "${home}/.logs
			chmod 750 "${home}/.logs
			cp "/etc/skel/.scrips/${scriptBase}.exp" "${home}/.scripts/.
			chmod 750                                "${home}/.scripts/${scriptBase}.exp"
			cp "/etc/skel/.vpn.conf"                 "${home}/."
			chmod 600                                "${home}/.vpn.conf"
END-OF-CMDS
)
	done
}

