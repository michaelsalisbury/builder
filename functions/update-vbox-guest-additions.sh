#!/bin/bash


function main(){
	local vboxVer=$(GET_VBox_Ver)
	grep "^${vboxVer}$" "/etc/vboxVer" &>/dev/null	&&\
	echo "VBoxVer :: ${vboxVer} already installed"	&&\
	exit 0
	echo $vboxVer > "/etc/vboxVer"
	setup_VBox_Additions
}
function GET_Linux_Distrib(){
	if [ -f "/etc/lsb-release" ]; then
		awk -F= '/DISTRIB_ID/{print $2}'
	elif [ -f "/etc/redhat-release" ]; then
		echo Redhat
	else
		echo unknown
		exit 0
	fi
}
function GET_VBox_Ver(){
	local count=3
	while (( count-- )); do
		which dmidecode &>/dev/null && break
		case "$(GET_Linux_Distrib)" in
			Ubuntu)	apt-get -y install dmidecode;;
			Redhat)	yum -y install dmidecode;;
			*)	exit 0;;
		esac
	done
	dmidecode | awk -F_ '/vboxVer/{print $2}' | grep "" || exit 0
}
function setup_VBox_Additions(){
	# Prep for vbox extentions
	case "$(GET_Linux_Distrib)" in
		Ubuntu)	apt-get -y install make gcc dkms xserver-xorg xserver-xorg-core linux-headers-generic;;
		Redhat) yum     -y install make gcc dkms kernel-headers;;
	esac

	# prep working dirs
	mkdir        /root/vbox_guest_additions
        mkdir        /root/vbox_guest_additions/ISO
        cd           /root/vbox_guest_additions

	# Get version of latest release
        #rm -f                   /root/vbox_guest_additions/LATEST.TXT
        #wget -nv http://download.virtualbox.org/virtualbox/LATEST.TXT 
        #cat                     /root/vbox_guest_additions/LATEST.TXT
        #local      version=`cat /root/vbox_guest_additions/LATEST.TXT`
	local version=$(cat "/etc/vboxVer")

	# Get VBoxGuestAdditions ISO
	local iso="VBoxGuestAdditions_${version}.iso"
	[ ! -f "/root/vbox_guest_additions/${iso}" ] && \
        wget -nv http://download.virtualbox.org/virtualbox/${version}/${iso}
	
	# Add vbox user and group to specific uid and gid
	if ! grep -q "^vboxadd:" "/etc/passwd"; then
		local ID=$(free_ID_pair 100)
		useradd  -u $ID -g 1 -M -d /var/run/vboxadd -s /bin/false vboxadd
		groupadd -g $ID                                           vboxsf
		# Modify /etc/adduser.conf to include new group vboxsf
		case "$(GET_Linux_Distrib)" in
			Ubuntu)	add_default_group vboxsf;;
		esac
	fi

	# Mount VBoxGuestAdditions ISO
	umount                                        /root/vbox_guest_additions/ISO
	opt="-t iso9660 -o ro,loop"
        mount $opt  /root/vbox_guest_additions/${iso} /root/vbox_guest_additions/ISO

	# Install VBoxGuestAdditions 
	/root/vbox_guest_additions/ISO/VBoxLinuxAdditions.run

	# Unmount VBoxGuestAdditions ISO and clean up
	umount                                        /root/vbox_guest_additions/ISO
        unset version
        unset isoi
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
	local file=${1//[^a-zA-Z]/}
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
function add_default_group(){
	local group=$1
	sed -i "/^.*EXTRA_GROUPS=/s/^[# ]*//"                     /etc/adduser.conf
        sed -i "/^EXTRA_GROUPS=/{/${group}/!s/\"$/ ${group}\"/;}" /etc/adduser.conf
        sed -i '/^ADD_EXTRA_GROUPS=.*/cADD_EXTRA_GROUPS=1'        /etc/adduser.conf
}
buildScriptFQFN=$(readlink -nf "${BASH_SOURCE}")
buildScriptName=$(basename "${buildScriptFQFN}")
buildScriptPath=$(dirname  "${buildScriptFQFN}")

source="https://raw.github.com/michaelsalisbury/builder/master/functions/${buildScriptName}"

main "$@"




