#!/bin/builder.sh
skip=( false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/global/$scriptName

###########################################################################################
#                                                                   Users and Passwords
###########################################################################################
function set_user_passwd(){
	local username=$1
	local password=$2
	perl -e 'system("usermod -p ".crypt($ARGV[1], rand)." $ARGV[0]")' $username $password
}
function add_admin_user(){
	local username=$1
	local password=$2
	useradd  -m -s /bin/bash                         ${username}
	set_user_passwd                                  ${username} $password
	usermod -a -G adm,cdrom,sudo,dip,plugdev,lpadmin ${username}
	set_ssh_authorized_keys                          ${username}
}
function add_basic_user(){
	local username=$1
	local password=$2
	useradd  -m -s /bin/bash                         ${username}
	set_user_passwd                                  ${username} $password
	set_ssh_authorized_keys                          ${username}
}
function get_user_details(){
	# Returns; username uid gid home
	local ID=$1
	shopt -s nocasematch
	if [ "$ID" == "all" ]; then
		read -d $'' awk << END-OF-AWK
		{if (((\$3 >= 1000)||(\$1 == "root"))&&(\$1 != "nobody"))
			{print \$1" "\$3" "\$4" "\$6;}
		}
END-OF-AWK
	else
		read -d $'' awk1 << END-OF-AWK
		{if ((\$1 == "$ID")||(\$3 == "$ID"))
			{print \$1" "\$3" "\$4" "\$6;}
		}
END-OF-AWK
	fi
	shopt -u nocasematch
	awk -F: "${awk}" /etc/passwd
}
function add_default_group(){
	local group=$1
	sed -i "/^.*EXTRA_GROUPS=/s/^[# ]*//"                     /etc/adduser.conf
        sed -i "/^EXTRA_GROUPS=/{/${group}/!s/\"$/ ${group}\"/;}" /etc/adduser.conf
        sed -i '/^ADD_EXTRA_GROUPS=.*/cADD_EXTRA_GROUPS=1'        /etc/adduser.conf
}
function del_default_group(){
	local group=$1
	local groups=$(sed '/^EXTRA_GROUPS.*/p;d' /etc/adduser.conf)
	if [[ "${groups}" =~ ^$ ]]; then
		return 0;
	elif [[ "${group}" =~ "${group}" ]]; then
		sed -i "/^EXTRA_GROUPS.*${group}/s/[ ]?${group}//" /etc/adduser.conf
		return $?
	fi
	return 1
}
