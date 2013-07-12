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

function setup_skel_Structure(){
	desc Build skel directory structure
	mkdir -p   /etc/skel/.scripts
	chmod 700  /etc/skel/.scripts
	mkdir -p   /etc/skel/.logs
	chmod 700  /etc/skel/.logs
	local scriptBase=$(basename "${scriptName}" .sh)
	cp "${scriptPath}/${scriptBase}.exp" /etc/skel/.scripts/openconnect.exp
	chmod u+x                            /etc/skel/.scripts/openconnect.exp
	touch      /etc/skel/.vpn.cred
	chmod 600  /etc/skel/.vpn.cred
	touch      /etc/sudoers.d/openconnect
	chmod 440  /etc/sudoers.d/openconnect
	groupadd -g $(free_ID_pair 100) openconnect
}
function setup_make_Config(){
	desc Setting up default config
	cat <<-END-OF-ALIASES > /etc/profile.d/openconnect.sh
		alias vpno='openconnect \$(awk -F'\''[= ]*'\'' '\''/^url/{print \$2}'\'' \${HOME}/.vpn.cred)'
		#alias vpnc='\${HOME}/.scripts/openconnect.exp &\| tail -a \${HOME}/.logs/openconnect'
		alias vpnc='\${HOME}/.scripts/openconnect.exp &> \${HOME}/.logs/openconnect &'
		alias vpnd='sudo killall openconnect'
		alias vpns='ifconfig tun; tail \${HOME}/.logs/openconnect'
	END-OF-ALIASES
	cat <<-END-OF-VPNCONF > /etc/skel/.vpn.cred
		username = [NID]
		password = [***]
		group    = [ucffaculty|ucfstudent]
		url      = ucfvpn-1.vpn.ucf.edu
	END-OF-VPNCONF
	cat <<-END-OF-SUDOERS > /etc/sudoers.d/openconnect
		# openconnect
		%openconnect ALL=(root) NOPASSWD:/usr/sbin/openconnect
		%openconnect ALL=(root) NOPASSWD:/usr/bin/killall openconnect
	END-OF-SUDOERS
	# Modify /etc/adduser.conf to include new group openconnect
	add_default_group openconnect
}
function setup_distribute_Config(){
	desc setting up default config \for existing users
	#chmod +r /etc/skel/.scripts
	#chmod +r /etc/skel/.vpn.cred
	#local scriptBase=$(basename "${scriptName}" .sh)
	get_user_details all | while read user uid gid home; do
		echo Setting up openconnect for user[${user}]
		usermod -a -G openconnect ${user}
		su - ${user} -s /bin/bash <<-SU
			mkdir -p  "\${HOME}/.scripts"
			chmod 700 "\${HOME}/.scripts"
			mkdir -p  "\${HOME}/.logs"
			chmod 700 "\${HOME}/.logs"
			touch     "\${HOME}/.scripts/openconnect.exp"
			chmod 700 "\${HOME}/.scripts/openconnect.exp"
			touch     "\${HOME}/.vpn.cred"
			chmod 600 "\${HOME}/.vpn.cred"
		SU
		[ -f "${home}/.scripts/openconnect.exp" ] && ! (( 
		cat /etc/skel/.scripts/openconnect.exp > "${home}/.scripts/openconnect.exp"
		[ -f "${home}/.vpn.cred"
	done
	chmod 700 /etc/skel/.scripts
	chmod 600 /etc/skel/.vpn.cred
}

