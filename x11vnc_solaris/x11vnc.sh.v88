#!/bin/bash
#https://wiki.archlinux.org/index.php/X11vnc

function main(){
	echo -------------------------------------------------------- `date "+%Y.%m.%d-%T"`
	#env
	#echo --------------------------------------------------------

	# These two GLOBAL vars must be captures ASAP or the connection times out
	GET_PROC_SOCKETS  $$ &>/dev/null		# Set GLOBAL var SOCKETS
	GET_PROC_SRC_PID  $$ &>/dev/null		# Set GLOBAL var SRCPID
	GET_PROC_SRC_UID  $$ &>/dev/null		# Set GLOBAL var SRCUID
	GET_PROC_SRC_USER $$ &>/dev/null		# Set GLOBAL var SRCUSER

	# enter into array "auth_array" the xauth display sockets sorted by newest first
	if IS_OS_REDHAT; then
		IFS=$'\n' read -d $'' -a auth_array < <(ls -tc /var/run/gdm/*/database)
	elif IS_OS_UBUNTU; then
		IFS=$'\n' read -d $'' -a auth_array < <(ls -tc /var/run/lightdm/root/\:0)
	elif IS_OS_SOLARIS; then
		IFS=$'\n' read -d $'' -a auth_array < <(ls -tc /var/run/gdm/*/database)
	fi
	
	# log "auth_array" socket list
	# for auth in "${auth_array[@]}"; do echo gdmDB $(( auth_count++ )) : ${auth}; done

	# get the name of the user logged into DISPLAY :0
	local DISPLAY_0_USER=$(who -u | awk '/tty.*\(:0/{print $1}')
	
	echo DISPLAY : ${DISPLAY_0_USER}	

	# get connecting username
	local srcUSER=`GET_PROC_SRC_USER $$`
	local vncPORT=`GET_PROC_DST_PORT $$`
	local usrHOME=`GET_USER_HOMEDIR ${srcUSER}`
	
	# get sockets
	local -a sockets=( `GET_PROC_SOCKETS $$` )
	local vncSOCK=${sockets[0]}
	local usrSOCK=${sockets[1]}

	# test if connecting user is allowed
	IS_USER_ALLOWED ${srcUSER} ${vncPORT} "$@" || exit 1
	IS_USER_ADMIN   ${srcUSER} && echo _INFO_ :: User is admin

	# if no users are logged on then jump in
	if [ -z "${DISPLAY_0_USER}" ]; then
		echo CONNECTING\!\!\! User \"${srcUSER}\" to welcome screen.
		echo CONNECTING\!\!\! User \"${srcUSER}\" is connecting with\
			VNC via $'('${vncSOCK}$')'.

	# if connecting user and local user match than jump in
	elif [ "${DISPLAY_0_USER}" == "${srcUSER}" ]; then
		DISPLAY_UNLOCK ${DISPLAY_0_USER}
		echo CONNECTING\!\!\! User \"${srcUSER}\" is re-connecting with\
			VNC via $'('${vncSOCK}$')'.

	# if connecting user is root then jump in
	elif [ "root" == "${srcUSER}" ]; then
		DISPLAY_UNLOCK ${DISPLAY_0_USER}
		echo CONNECTING\!\!\! User \"${srcUSER}\" is connecting with\
			VNC via $'('${vncSOCK}$')'.

	# if connecting users is an admin as defined in Xcommon-functions
	# admin users currently defined as root or member of the wheel group
	elif IS_USER_ADMIN ${srcUSER}; then
		DISPLAY_UNLOCK ${DISPLAY_0_USER}
		echo CONNECTING\!\!\! wheel User \"${srcUSER}\" is connecting with\
			VNC via $'('${vncSOCK}$')'.

	# if a user is logged in but the screen is locked allow access
	elif DISPLAY_ISLOCKED ${DISPLAY_0_USER}; then
		echo CONNECTING\!\!\! User \"${DISPLAY_0_USER}\" is logged in with\
			screensaver active.
		echo CONNECTING\!\!\! User \"${srcUSER}\" is connecting with\
			VNC via $'('${vncSOCK}$')'.

	# if a user is logged in and active then prompt the user to allow access
	else
		echo CONNECTING\!\!\! User \"${srcUSER}\" posting query to\
			${DISPLAY_0_USER} for access.

		cat <<-ZENITY | su - ${DISPLAY_0_USER} -s /bin/bash
			DISPLAY=:11 zenity		\
				--question		\
				--timeout=10		\
				--ok-label="Allow"	\
				--cancel-label="NO"	\
				--title="Remote user attempting connection ALLERT"\
				--text="User \"${srcUSER}\" wants to share your desktop"
		ZENITY
		local zenity_dlg=$?
		case ${zenity_dlg} in
			0|5)	echo CONNECTING\!\!\! User \"${srcUSER}\" is connecting with\
					VNC via $'('${vncSOCK}$')'.;;
			1)	echo EXITING\!\!\! User \"${DISPLAY_0_USER}\"\
					said NO to \"${srcUSER}\"\!
				exit ${dlgDATA};;
			*)	echo ERROR\!\!\! Unknown error code from zenity\;\
					${zenity_dlg}
				exit ${dlgDATA};;
		esac
	fi

	# start x11vnc socket on localhost
	/usr/bin/x11vnc				\
		-bg				\
		-ncache				\
		-o "${LOG}.${vncPORT}"		\
		-accept /bin/true		\
		-gone /bin/true			\
		-noxdamage			\
		-forever			\
		-inetd				\
		-localhost			\
		-noipv4				\
		-noipv6				\
		-rfbport 0			\
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
	#cat <<-END-OF-SU | su ${username} -s /bin/bash -l
	#	cat <<-END-OF-BASH | bash
	#		DISPLAY=:0 zenity ${dlgOPTS[*]}
	#	END-OF-BASH
	#END-OF-SU
	cat <<-END-OF-SU | su ${username} -s /bin/bash -l
		DISPLAY=:0 zenity ${dlgOPTS[*]}
	END-OF-SU
	echo ERROR_MSG :: returned $? :: ${dlgTEXT}
}
function canonicalpath(){
	if [ -d $1 ]; then
		pushd $1 > /dev/null 2>&1
		echo $PWD
	elif [ -f $1 ]; then
		pushd $(dirname $1) > /dev/null 2>&1
		echo $PWD/$(basename $1)
	else
		echo "Invalid path $1"
	fi
	popd > /dev/null 2>&1
}
# GLOBAL vars; fully qualified script paths and names
BASH_SRCFQFN=$(canonicalpath "${BASH_SOURCE}")
BASH_SRCNAME=$(basename "${BASH_SRCFQFN}")
BASH_SRCDIR=$(dirname "${BASH_SRCFQFN}")

# GLOBAL vars; Temp directory for fifo locations
TMP="/tmp/$$_${BASH_SRCNAME}_$$"
mkdir "${TMP}"

# GLOBAL vars; daemon config directory
CONFIG_FOLDER=${BASH_SRCDIR}

# GLOBAL vars; LOG file set so that xstartup can write to it.
LOG=/var/log/${BASH_SRCNAME//.sh/.log}
touch     ${LOG}
chmod 777 ${LOG}

# Source Xcommon-functions
[ -f "${CONFIG_FOLDER}/Xcommon-functions.sh" ] &&\
	source "${CONFIG_FOLDER}/Xcommon-functions.sh" >> "${LOG}" 2>&1

# set DEBUG to true for excessive function logging
DEBUG=true
DEBUG=false

main "$@" 1>> "${LOG}" 2>> "${LOG}.e"
