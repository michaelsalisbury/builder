#!/bin/builder.sh
skip=( false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

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
		"/usr/bin/gnome-session --session=gnome-classic" \
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
