#!/bin/bash
#https://wiki.archlinux.org/index.php/X11vnc

LOG=/var/log/x11vnc.helper

function main(){
	echo -------------------------------------------------------- `date "+%Y.%m.%d-%T"`
	env
	echo --------------------------------------------------------
	# to create password file "x11vnc -storepasswd" the password will be stored in
	# ~/.vnc/passwd and can be relocated as nessisary
	# currently this script does not use a password file
	rfbauth_passwd_file=/etc/x11vnc/passwd

	# enter into array "auth_array" the xauth display sockets sorted by newest first
	IFS=$'\n' read -d $'' -a auth_array < <(ls -tc /var/run/gdm/*/database)
	
	# log "auth_array" socket list
	for auth in "${auth_array[@]}"; do echo gdmDB $(( auth_count++ )) : ${auth}; done

	# get the name of the user logged into DISPLAY :0
	local user_logged_into_DISPLAY0=$(who -u | awk '/tty.*\(:0/{print $1}')
	
	echo DISPLAY : ${user_logged_into_DISPLAY0}	
	echo srvARGS : "$@"
	echo x11PID :: $$
	echo x11PPID : $PPID
	echo x11prog : $(basename "${BASH_SOURCE}")

	# get sockets
	local ock='\([0-9\.]\+:[0-9]\+\)'	# sed socket filter
	local p='[[:space:]]'			# sed white space key
	# "/,$$,/s/.*[[:s:]]\([0-9\.]\+:[0-9]\+\)[[:s:]]*\([0-9\.]\+:[0-9]\+\)[[:s:]].*/p;d"
	local -a sockets=($(ss -np | sed "/,$$,/s/.*$p$ock$p*$ock$p.*/\1 \2/p;d"))
	
	# get connecting pid
	local srcPID=$(\
		ss -n -p src ${sockets[1]} |\
		sed 's/.*[[:space:]]\+users:(("[[:graph:]]\+",\([0-9]*\),.*/\1/p;d')

	# get connecting ppid
	local srcPPID=$(ps --no-heading -o ppid -p ${srcPID})

	# get connecting userID
	local srcUID=$(ps --no-heading -o uid -p ${srcPID})
	
	# get connecting username
	local srcUSER=$(ps --no-heading -o user -p ${srcPID})

	echo d sock :: ${sockets[0]}
	echo s sock :: ${sockets[1]}
	
	echo x11PID :: $$
	echo x11PPID : $PPID
	echo srcPID :: ${srcPID}
	echo srcPPID : ${srcPPID}
	echo srcUID :: ${srcUID}
	echo srcUSER : ${srcUSER}

	# parse args for users and groups and add then to array "users"
	IFS=$'\n' read -d $'' -a allowed_users < <(
		for name in "$@"; do
			awk -F: -v NAME="${name}" \
				'$0~"^"NAME {
					NAME=""
					sub(/(^[, ]*|[, ]*$)/,"",$4)
					gsub(",","\n",$4)
					printf ($4==""?$1:$4)
					exit
				}END{
					printf NAME"\n"
				}' \
			/etc/group
		done)

	# log userlist
	echo srvARGS : ${allowed_users[*]}

	# append root and wheel users to allowed_user array
	local allowed_users_index=${#allowed_users[*]}
	for name in root $(awk -F: '/^wheel:/{gsub(","," ",$4);print $4}' /etc/group); do
		allowed_users[$(( allowed_users_index++ ))]="${name}"
	done
	echo

	# test if connecting user was not on the allowed_users array list
	if ! $(IFS=$'\n'; echo "${allowed_users[*]}" | grep -q "^${srcUSER}$"); then
		ERROR_MSG User [${srcUSER}] tried to VNC via $'\('${sockets[0]}$')'. &
		echo EXITING\!\!\! User \"${srcUSER}\" tried to\
			VNC via $'('${sockets[0]}$')'.
		exit 1
	fi

	# if no users are logged on then jump in
	if [ -z "${user_logged_into_DISPLAY0}" ]; then
		echo CONNECTING\!\!\! User \"${srcUSER}\" to welcome screen.
		echo CONNECTING\!\!\! User \"${srcUSER}\" is connecting with\
			VNC via $'('${sockets[0]}$')'.

	# if connecting user and local user match than jump in
	elif [ "${user_logged_into_DISPLAY0}" == "${srcUSER}" ]; then
		DISPLAY_UNLOCK ${user_logged_into_DISPLAY0}
		echo CONNECTING\!\!\! User \"${srcUSER}\" is re-connecting with\
			VNC via $'('${sockets[0]}$')'.

	# if connecting user is root then jump in
	elif [ "root" == "${srcUSER}" ]; then
		DISPLAY_UNLOCK ${user_logged_into_DISPLAY0}
		echo CONNECTING\!\!\! User \"${srcUSER}\" is connecting with\
			VNC via $'('${sockets[0]}$')'.

	# if connecting users belongs to the wheel group then jump in
	elif grep -q "^wheel:.*${srcUSER}" /etc/group; then
		DISPLAY_UNLOCK ${user_logged_into_DISPLAY0}
		echo CONNECTING\!\!\! wheel User \"${srcUSER}\" is connecting with\
			VNC via $'('${sockets[0]}$')'.

	# if a user is logged in but the screen is locked allow access
	elif DISPLAY_ISLOCKED ${user_logged_into_DISPLAY0}; then
		echo CONNECTING\!\!\! User \"${srcUSER}\" is connected with\
			screensaver active.
		echo CONNECTING\!\!\! User \"${srcUSER}\" is connecting with\
			VNC via $'('${sockets[0]}$')'.

	# if a user is logged in and active then prompt the user to allow access
	else
		echo CONNECTING\!\!\! User \"${srcUSER}\" posting query to\
			${user_logged_into_DISPLAY0} for access.

		local dlgOPTS=(
			--question
			--timeout=10
			--ok-label=\"Allow\"
			--cancel-label=\"NO\"
			--title=\"Remote user attempting connection ALLERT\"
			--text=\"User \\\"${srcUSER}\\\" wants to share your desktop\"
		)
		su ${user_logged_into_DISPLAY0}	\
			-s /bin/bash		\
			-c "DISPLAY=:0 zenity ${dlgOPTS[*]}"
		local dlgDATA=$?
		#echo DIALOG RESULYS :: ${dlgDATA}		

		if (( dlgDATA > 0 )); then
			echo EXITING\!\!\! User \"${user_logged_into_DISPLAY0}\"\
				said NO to \"${srcUSER}\"\!
			exit ${dlgDATA}
		else
			echo CONNECTING\!\!\! User \"${srcUSER}\" is connecting with\
				VNC via $'('${sockets[0]}$')'.
		fi
	fi

	# start x11vnc socket on localhost
	/usr/bin/x11vnc				\
		-bg				\
		-o /var/log/x11vnc.log		\
		-accept /bin/true		\
		-gone /bin/true			\
		-noxdamage			\
		-forever			\
		-inetd				\
		-localhost			\
		-display :0			\
		-auth ${auth_array[0]}		\
		-nopw
}
function DISPLAY_ISLOCKED(){
	local username=$1
	su ${username}		\
		-s /bin/bash	\
		-c "DISPLAY=:0 gnome-screensaver-command -q | grep -q \" active\""
}


function DISPLAY_UNLOCK(){
	local username=$1
	su ${username}		\
		-s /bin/bash	\
		-c "DISPLAY=:0 gnome-screensaver-command -d"
}
function ERROR_MSG(){
	local dlgTEXT="$@"
	local username=$(who -u | awk '/tty7.*\(:0/{print $1}')
	local dlgOPTS=(
		--error
		--timeout=15
		--title=\"Remote user attempting connection: ALLERT\"
		--text=\"${dlgTEXT}\"
	)
	cat <<-END-OF-SU | su ${username}
		cat <<-END-OF-BASH | bash
			DISPLAY=:0 zenity ${dlgOPTS[*]}
		END-OF-BASH
	END-OF-SU
	echo ERROR_MSG :: returned $? :: ${dlgTEXT}
}

main "$@" 2>&1 >> "${LOG}"
