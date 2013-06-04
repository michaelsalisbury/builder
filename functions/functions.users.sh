#!/bin/builder.sh
skip=( false )
step=1
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/functions/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName

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
		cat <<-AWK | awk -F: -f <(cat) /etc/passwd
			{if (((\$3 >= 1000)||(\$1 == "root"))&&(\$1 != "nobody"))
				{print \$1" "\$3" "\$4" "\$6;}
			}
		AWK
	else
		cat <<-AWK | awk -F: -f <(cat) /etc/passwd
			{if ((\$1 == "$ID")||(\$3 == "$ID"))
				{print \$1" "\$3" "\$4" "\$6;}
			}
		AWK
	fi
	shopt -u nocasematch
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
function free_group_ID(){
	free_ID UID ${1}
}
function free_user_ID(){
	free_ID GID ${1}
}
function free_UID(){	
	free_ID UID $1
}
function free_GID(){
	free_ID GID $1
}
function free_ID_pair(){
	local uid=$(free_UID $1)
	local gid=$(free_GID ${uid})
	if (( uid == gid )); then
		echo ${uid}
	else
		free_ID_pair ${gid}
	fi
} 
function free_ID(){
	local file=${1//[^a-Z]/}
	case ${file} in
		group|passwd)	local ID=${2:-\1};;
		g*|G*)		free_ID group ${2//[^0-9]/}
				return 0;;
		p*|P*|u*|U*)	free_ID passwd ${2//[^0-9]/}
				return 0;;
		*)		free_ID ${file:-passwd} ${1//[^0-9]/}
				return 0;;
	esac

	if ! grep -q ^${ID}$ <(cut -d: -f3 /etc/${file}); then
		echo $ID
	else
		let ID++
		free_ID ${file} ${ID}
	fi
}
