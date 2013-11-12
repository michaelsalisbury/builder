#!/bin/builder.sh
skip=( false )
step=1
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/functions/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName

###########################################################################################
#                                                                Uncategorized
###########################################################################################
function word_split(){
        local divide=$1
        shift
        local delimiter=$1
        [ -z "${delimiter}" ] && local delimiter=' '
        shift
        if (( ${#@} > 0 )); then
                echo "$@" | $FUNCNAME ${divide} "${delimiter}"
                return
        fi
        local word=""
        while read word; do
                local length=${#word}
                local remainder=$(( length % divide ))
                if [[ "${divide}" =~ ^- ]]; then
                        divide=${divide:1}
                        local start=$remainder
                        unset end
                        (( remainder )) \
                                && local beginning=\${word:0:$remainder} \
                                || unset beginning
                else
                        local start=0
                        unset beginning
                        (( remainder )) \
                                && local end=\${word:$(( length - remainder )):$remainder} \
                                || unset end
                fi
                local finish=$(( length - divide ))

                local middle=`seq $start $divide $finish | awk -v divide=$divide '{print "${word:"$0":"divide"}"}'`
                      middle=${middle//$'\n'/$delimiter}

                local eval_str+=${beginning}
                      eval_str+=${beginning+$delimiter}
                      eval_str+=${middle}
                      eval_str+=${end+$delimiter}
                      eval_str+=${end}

                eval echo \"${eval_str}\"
        done
}
function ip_to_bin(){
        if (( ${#@} > 0 )); then
                echo "$@" | $FUNCNAME
                return
        fi
        local ip=""
        while read ip; do
                [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo input-not-ip && return 1; }
                echo `echo "ibase=A;obase=2;${ip//\./$';'}" | bc | awk '{printf "%08.0f", $0}'`
        done
}
function bin_to_ip(){
        if (( ${#@} > 0 )); then
                echo "$@" | $FUNCNAME
                return
        fi
        local bin=""
        while read bin; do
                (( ${#bin} == 32 )) || { echo input-not-32-bit-binary-number && return 1; }
                local ip=`echo "ibase=2;obase=A;$(word_split -8 ';' $bin)" | bc`
                echo ${ip//$'\n'/.}
        done
}

###########################################################################################
#                                                                SSH Keys
###########################################################################################
function set_ssh_authorized_keys(){
	local ID=$1
	set_ssh_authorized_key $ID ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAofjHmUuZrNEsTUSx/Agb5bJOGP57DvbLxAh9xsBniAvyA7I3X68TAJZixWKQEs4SbhNhkO5wcZwC/9k/j2GXpvKEFewscxlw9X1/Mcxcpndl94Yptei2klBb5WKNSFJ06GxkxM/AtfXK6IQtKr/qiQfg/pdvwQ/X51kKFp8DQdiaUz5GgEqh19y6+uCfqGJsOkNph/9cGJGeJxRxJjuwghI3fmb9QapxLSqcQBJ++0GDo4UyO5smJgBiyL96g3sOzB4H/UMGdnQqsemLGvRmu60Jmy15D0I1XDfcN29kYOfoxYzkpbxvp3P9F/BL/Yao/J3x1Cz1U17GqRduTgnwrQ== root@RHEL01.localdomain
	set_ssh_authorized_key $ID ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAmMckh4/gd/8LK4wpmhdcnSEzLuDR+aiNojMI5j3enNRiJ4Kml4+JxlwllosZW2soz8i6THVEzp24d39XrfrXmopXQaUr+D41ES0WDbq0ZNu2hxLVxwLFimbo7xdRKs5+e8VuBBbH7gIvGYdmUGWEN8972S2UJpJnupgw4WaOg8U= rsa-key-20110617
	set_ssh_authorized_key $ID ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzIO6rkj+CGBs4caGagQgZb18JALME2x8dD1HHgEjNJ2waB/MAsEPa80QZm1hQydjt5T5Sz2Ni9sayeOYAXHNLydmzoOWqw2Hd0I9LiSx6Kw9c7D+27RDjXgEjo6cCAgDRH9IL6tqVWzwGAYb3hx7O+u4ZYuByYzzClvzFpfVFOtffS+f/8qQfGHElCP3RZSZaNzy5HAx2P4Y5cRKhGLDyitOTe1aBAMUVjDQybSMc8nV0Z7T8A7pa+6/JncxqYvTjYY6YlVwiZesImjjo2tkvH1QT5N2z6lc2NTePF5FI+INiO9UJvqRXdTxxdtm2kwbk4sAAbvWEDWOFPh+53RTQQ== root@pxe.pig.pie
}
function set_ssh_authorized_key(){
	local ID=$1
	shift
	local KEY=$@
	get_user_details $ID | while read user uid gid home; do
		[ ! -e "${home}" ] && continue
		mkdir -p             "${home}/.ssh"
		echo $KEY >>         "${home}/.ssh/authorized_keys"
		chown -R $user:$user "${home}/.ssh"
		chown -R $uid        "${home}/.ssh"
		chgrp -R $gid        "${home}/.ssh"
		chmod     744        "${home}/.ssh"
		chmod     600        "${home}/.ssh/authorized_keys"
	done
}
###########################################################################################
#                                                                AutoLogin User and Session
###########################################################################################
function set_lightdm(){
	local autoLoginUsr=$1
	local defaultShell=$2
	local etDMDefaults='/usr/lib/lightdm/lightdm-set-defaults'
	# valid session names /usr/share/xsessions
	#$etDMDefaults --autologin		$autoLoginUsr
	$etDMDefaults --session			$defaultShell
	#$etDMDefaults --show-manual-login	true
	#$etDMDefaults --show-remote-login	true
	#$etDMDefaults --allow-guest		true
	#$etDMDefaults --greeter
	return 0
	cat << END-OF-LIGHTDM > /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-guest=false
autologin-user=${username}
autologin-user-timeout=0
autologin-session=lightdm-autologin
#user-session=ubuntu
#user-session=xfce4-session
#user-session=gnome-fallback
user-session=${loginShell}
greeter-session=unity-greeter
END-OF-LIGHTDM
}
###########################################################################################
#                                                                Toprc
###########################################################################################
function set_toprc(){
	read user uid gid home < <(get_user_details $1)
	echo $user $home $gid $uid
	touch                 "${home}/.toprc"
	chown $uid            "${home}/.toprc"
	chgrp $gid            "${home}/.toprc"
	cat << END-OF-TOPRC > "${home}/.toprc"
RCfile for "top with windows"           # shameless braggin'
Id:a, Mode_altscr=0, Mode_irixps=1, Delay_time=3.000, Curwin=0
Def     fieldscur=AEHIOQTWKNMbcdfgjplrsuvyzX
        winflags=32569, sortindx=10, maxtasks=0
        summclr=1, msgsclr=1, headclr=3, taskclr=1
Job     fieldscur=ABcefgjlrstuvyzMKNHIWOPQDX
        winflags=62777, sortindx=0, maxtasks=0
        summclr=6, msgsclr=6, headclr=7, taskclr=6
Mem     fieldscur=ANOPQRSTUVbcdefgjlmyzWHIKX
        winflags=62777, sortindx=13, maxtasks=0
        summclr=5, msgsclr=5, headclr=4, taskclr=5
Usr     fieldscur=ABDECGfhijlopqrstuvyzMKNWX
        winflags=62777, sortindx=4, maxtasks=0
        summclr=3, msgsclr=3, headclr=2, taskclr=3
END-OF-TOPRC
}
###########################################################################################
#                                                                xinit
###########################################################################################
function xinit_start(){
	local user=${1:- root}
	xinit 	/bin/su ${user} -c \
		"/usr/bin/gnome-session --session=gnome-fallback" \
		-- :1 vt8 &> /dev/null &
}
function xinit_stop(){
	local user=${1:- root}
	#xhost +SI:localuser:${user}
	export DISPLAY=:1
	su ${user} -c "gnome-session-quit --no-prompt"
}
function xinit_run(){
	local user=${1:- root}
	# test if arg 1 is a local user, shift if true
	egrep -q "^$1" /etc/passwd && shift || local user=root
        # preserve quotes
	local CMD=( "${@}" )
	local CMD=( ${CMD[@]//\ /::SPACE::} )
	local CMD=( ${CMD[@]/#/\\\\$'"'} )
	local CMD=( ${CMD[@]/%/\\\\$'"'} )
	local CMD=( ${CMD[@]//::SPACE::/\ } )
	#xhost +SI:localuser:${user}
	export DISPLAY=:1
	read -d $'' CMDS << END-OF-CMDS
        	for x in {10..1}; do
        	        echo -n \\\\\$x..
        	        sleep .5
        	done;	echo

		/bin/bash -c '${CMD[@]}'

        	for x in {5..1}; do
        	        echo -n \\\\\$x..
        	        sleep .5
        	done;	echo
END-OF-CMDS
	cat << END-OF-SU | su ${user}
		terminator -m -e "${CMDS}"
END-OF-SU
}
###########################################################################################
#                                                                Hardware Identification
###########################################################################################
function system_dmidecode_strings(){
	if ! which dmidecode &>/dev/null; then
		echo na
		return 1
	fi
	sudo dmidecode -s 2>&1	|\
	tail -n +4		|\
	while read STR; do
		echo -n ${STR} :: ''
		sudo dmidecode -s ${STR}
	done
}
function system_hardware_platform_id(){
	if ! which dmidecode &>/dev/null; then
		echo noid
		return 1
	fi
	# currently programmed to ID Dell, VirtualBox, VMWare
	local SYSTEM_ID=""
	for SYSTEM_ID in	\
		dell		\
		virtualbox	\
		vmware		\
		noid
	do
		
		system_dmidecode_strings |\
		grep -q -i ${SYSTEM_ID} &&\
		break
	done
	echo ${SYSTEM_ID}
}
function system_uuid(){
	if ! which dmidecode &>/dev/null; then
		echo noserial
		return 1
	fi
	sudo dmidecode -s system-uuid
}
function system_serial(){
	# for virtualbox and vmware generate host version
	if ! which dmidecode &>/dev/null; then
		echo noserial
		return 1
	fi
	local SYSTEM_ID=$(system_hardware_platform_id)
	case "${SYSTEM_ID}" in
		dell)		local DELL_TAG=$(sudo dmidecode -s system-serial-number)
				local SERIAL=${DELL_TAG};;
		virtualbox)	local VBOX_VER=$(sudo dmidecode -u |\
					awk -F'_|"' '/vboxVer/{print $3}')
				local VBOX_REV=$(sudo dmidecode -u |\
					awk -F'_|"' '/vboxRev/{print $3}')
				SERIAL="VBox${VBOX_VER}-${VBOX_REV}";;
		vmware)		SERIAL="VMWare";;
		*)		SERIAL="${SYSTEM_ID}";;
	esac
	echo ${SERIAL}
}
function system_is_virtualbox(){
	system_hardware_platform_id | grep -q -i virtualbox
}
function system_is_vmware(){
	system_hardware_platform_id | grep -q -i vmware
}

###########################################################################################
#                                                                Ubuntu Policy
###########################################################################################
function policy_change(){
	default_policy_folder="/usr/share/polkit-1/actions"
	#policy="/usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy"
	#action="org.freedesktop.NetworkManager.settings.modify.system"

	find_policy="NetworkManager"
	find_action="system"
	old="auth_admin_keep"
	new="yes"
	find_policy="$1"
	find_action="$2"
	old="$3"
	new="$4"

	# verify all command arguments have deen supplied
	if [ -z "${find_policy}" ] ||\
	   [ -z "${find_action}" ] ||\
	   [ -z "${old}" ]         ||\
	   [ -z "${new}" ]; then
		echo ERROR! all command arguments not supplied!
		return 1
	fi

	# verify policy
	if [ -f "${find_policy}" ]; then
		policy=${find_policy}
	elif [ -f "${default_policy_folder}/${find_policy}" ]; then
		policy="${default_policy_folder}/${find_policy}"
	elif (( 1  ==  $(ls -1 "${default_policy_folder}" | egrep "${find_policy}" | wc -l) )); then
		policy=$(ls -1 "${default_policy_folder}" | egrep "${find_policy}")
		policy="${default_policy_folder}/${policy}"
	else
		echo ERROR! Policy File NOT found for search \"${find_policy}\"\!
		return 1
	fi

	# verify action
	if (( 1 == $(cat "${policy}" | grep "action id" | egrep "${find_action}" | wc -l) )); then
		action=$(cat "${policy}"		|\
			grep "action id"		|\
			egrep "${find_action}"		|\
			sed 's/.*id="\(.*\)">.*/\1/'	)
	elif (( 1 == $(cat "${policy}" | grep "action id" | egrep "${find_policy}.*${find_action}" | wc -l) )); then
		action=$(cat "${policy}"		|\
			grep "action id"		|\
			egrep "${find_action}"		|\
			sed 's/.*id="\(.*\)">.*/\1/'	)
	else
		echo ERROR! Action ID \"${find_action}\" NOT found in Policy File \"${policy}\"\!
		return 1
	fi

	# find line number to change
	line=$(	cat -n "${policy}"		|\
		grep "action id\|allow_active"	|\
		egrep -A1 "${action}"		|\
		tail -1				|\
		awk '{print $1}'		)

	# make change
	sed -i "${line}{ s/${old}/${new}/; }" "${policy}"
}	

