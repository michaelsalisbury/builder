#!/bin/bash
#https://wiki.archlinux.org/index.php/X11vnc
DESKTOPS='gnome twm ice fluxbox xfce4 kde'
#rfbport=33607
#cat | /opt/csw/bin/nc 127.0.0.1 ${rfbport} &

function main(){
	echo ----------------------------------------- `date "+%Y.%m.%d-%T"`

	#DISPLAY_SETUP_DEFAULTS mi164210 5901
	
	# These two GLOBAL vars must be captures ASAP or the connection times out
	GET_PROC_SOCKETS  $$ &>/dev/null		# Set GLOBAL var SOCKETS
	GET_PROC_SRC_PID  $$ &>/dev/null		# Set GLOBAL var SRCPID
	GET_PROC_SRC_UID  $$ &>/dev/null		# Set GLOBAL var SRCUID
	GET_PROC_SRC_USER $$ &>/dev/null		# Set GLOBAL var SRCUSER

	# get connecting username
	local srcUSER=`GET_PROC_SRC_USER $$`
	local vncPORT=`GET_PROC_DST_PORT $$`
	local usrHOME=`GET_USER_HOMEDIR ${srcUSER}`
	
	echo ___PID :: $$
	echo ___GET :: src USER :: `GET_PROC_SRC_USER $$`
	echo ___GET :: src PID_ :: `GET_PROC_SRC_PID $$`
	echo ___GET :: src PORT :: `GET_PROC_SRC_PORT $$`
	echo ___GET :: vnc PORT :: `GET_PROC_DST_PORT $$`
	echo ___GET :: usr HOME :: `GET_USER_HOMEDIR $(GET_PROC_SRC_USER $$)`
	echo

	#GET_ALLOWED_USERS "$@"

	# test if connecting user was not on the allowed_users array list
	IS_USER_ALLOWED ${srcUSER} ${vncPORT} "$@" || exit 1
	IS_USER_ADMIN   ${srcUSER} 

	# load last known display port details (bewaire; these will be global)
	DISPLAY_READ_KEYS ${srcUSER} ${vncPORT}
	
	# verify that desktop selection is supported
	VERIFY_GLOBAL_DESKTOP ${srcUSER} ${vncPORT}

	# verify resolution is formatted correctly and in range
	VERIFY_GLOBAL_RESOLUTION ${srcUSER} ${vncPORT}

	# verify that depth is a positive integer
	# verify that depth is only values of 8, 16 & 24 (15 has font problems)
	VERIFY_GLOBAL_DEPTH ${srcUSER} ${vncPORT}

	# verify that Ubuntu gnome desktop has logout icon
	VERIFY_UBUNTU_GNOME_LOGOUT ${srcUSER} ${desktop}

	# echo vncserver setup details
	echo GLOBAL :: ________________________
        echo GLOBAL :: resolution :: ${resolution}
        echo GLOBAL :: ____ depth :: ${depth}
        echo GLOBAL :: __ desktop :: ${desktop}
	echo GLOBAL :: __ rfbport :: ${rfbport}
	echo GLOBAL :: ___ vncPID :: ${vncPID}
        echo GLOBAL :: vncDisplay :: ${vncDisplay}

	# test to see if display is still open 
	if IS_DISPLAY_OPEN ${srcUSER} ${vncPID} ${vncDisplay}; then
		echo _JUMP_ ::
	else
		# generate randome port number to create vncserver display: rfbport
		SET_FREE_LISTENING_PORT ${srcUSER} ${vncPORT}
		# write xstartup file
		SET_xstartup ${srcUSER}
		# Setup VNCDESKTOP environmental variable
		SET_VNCDESKTOP ${srcUSER} ${vncPORT} ${rfbport} ${desktop}
		echo GLOBAL :: VNCDESKTOP :: ${VNCDESKTOP}
		# setup vncserver display port
		su - ${srcUSER} $(IS_OS_SOLARIS || echo -s /bin/bash)\
		<<-END-OF-VNCSERVER-SETUP
			#export `grep ^PATH /etc/default/login`
			export PATH=${PATH}
			echo \${PATH} | tr ':' '\n' | sort
			VNCSERVER=\$(which vncserver 2>/dev/null | grep -v "^no")
			\${VNCSERVER}			\
				-SecurityTypes None	\
				-localhost		\
				-httpPort 0		\
				-nolisten tcp		\
				-geometry ${resolution}	\
				-depth ${depth}		\
				-rfbport ${rfbport}	\
				-name "${VNCDESKTOP}"	\
				$(IS_OS_SOLARIS || echo -autokill) 2>&1
		END-OF-VNCSERVER-SETUP
	fi
	echo --DONE----------------------------------- `date "+%Y.%m.%d-%T"`
}
function NETCAT(){
	local nc=$(WHICH nc)
	[ -x "${nc}" ] ||\
	{ echo BROKEN ?? The program \"nc\" could not be found\!; return 1; }
	cat | ${nc} 127.0.0.1 ${rfbport} &
	echo NETCAT :: sshTunnel PID :: $! >> "${LOG}"
}
function IS_DISPLAY_OPEN(){
	local username=$1
	local vncPID=$2
	local display=$3
	local homedir=$(GET_USER_HOMEDIR "${username}")
	#grep -q "^${vncPID}$" "${homedir}/.vnc/"*":${display}.pid" 2>&1 >> "${LOG}"
	#grep "^${vncPID}$" "${homedir}/.vnc/"*":${display}.pid" &> /dev/null
	if grep "^${vncPID}$" "${homedir}/.vnc/"*":${display}.pid" &>/dev/null; then
		if ps -p ${vncPID} -U ${username} -o comm | grep "^Xvnc$" &>/dev/null; then
			return 0	
		else
			return 1
		fi
	else
		return 1
	fi
}
function SET_vncPID(){
	local username=$1
	local vncPORT=$2
	local process=$3
	if (( ${#vncPID} > 0 )); then
		DISPLAY_WRITE_KEY ${username} ${vncPORT} vncPID
		echo ${vncPID} | DEBUGGER ==
	else
		local lsof=$(WHICH lsof 2>/dev/null)	
		[ -x "${lsof}" ] ||\
		{ echo BROKEN ?? The program \"lsof\" could not be found\!; return 1; }
		local LINE=""
		while read LINE; do
			case ${LINE:0:1} in
				p)	vncPID=${LINE:1}
					break;;
			esac
		done < <(
			${lsof} -n -P				\
				-p ^${process}			\
				-a				\
				-c Xvnc				\
				-a				\
				-i TCP@127.0.0.1:${rfbport}	\
				-F p
			)
		# write vncPID key to display file
		DISPLAY_WRITE_KEY ${username} ${vncPORT} vncPID
		echo ${vncPID} | DEBUGGER ==
	fi
}
function SET_vncDisplay(){
	local username=$1
	local vncPORT=$2
	local homedir=$(GET_USER_HOMEDIR "${username}")
	if (( ${#vncPID} == 0 )); then
		echo ERROR :: vncPID not set
		return 1
	else
		# get vncDisplay file
		#local vncPID_file=$(grep -l "${vncPID}" "${homedir}"/.vnc/*.pid &>/dev/null)
		local vncPID_file=$(grep -l "${vncPID}" "${homedir}"/.vnc/*.pid 2>&1 | tee >(DEBUGGER))
	fi
	# parse vncDisplay
	if (( ${#vncPID_file} > 0 )); then
		vncDisplay=$(basename "${vncPID_file}" .pid)
		vncDisplay=${vncDisplay#*:}
	else
		# if pid file missing then fail
		echo ERROR :: SET_vncDisplay failed.
		return 1
	fi
	# write vncDisplay key to display file
	DISPLAY_WRITE_KEY ${username} ${vncPORT} vncDisplay
}
function SET_xstartup(){
	local username=$1
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local xstartup="${homedir}/.vnc/xstartup"
	local Xstartup_MAIN="${CONFIG_FOLDER}/xstartup"
	local Xcommon_FUNCS="${CONFIG_FOLDER}/Xcommon-functions.sh"
	# if xstartup file exists and is diff then backup 
	if [ -f "${xstartup}" ] && ! \
	   diff "${xstartup}" "${Xstartup_MAIN}" &> /dev/null; then
		# if xstartup has already been backed-up then date stamp
		if find "${xstartup}".user* &> /dev/null; then
			mv -f "${xstartup}" "${xstartup}".user_$(date "+%s")
		else
			mv -f "${xstartup}" "${xstartup}".user
		fi
	fi
	# setup the custom xstartup file
	su - ${username} <<-SU
		cp -f "${Xcommon_FUNCS}" "${xstartup}.Xcommon"
		cp -f "${Xstartup_MAIN}" "${xstartup}"
		chmod +x                 "${xstartup}"
	SU
}
function SET_FREE_LISTENING_PORT(){
	local username=$1
	local vncPORT=$2
	rfbport=$(
		cat <<-PYTHON | python <(cat)
			import socket
			s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
			s.bind(("127.0.0.1", 0))
			s.listen(1)
			ipaddr, port = s.getsockname()
			print port
		PYTHON
	)
	echo CONFIG :: set free rfbport ${rfbport}
	# write new port number to displays file   
	DISPLAY_WRITE_KEY ${username} ${vncPORT} rfbport
}
function SET_VNCDESKTOP(){
	local username=$1
	local vncPORT=$2
	local rfbport=$3
	local desktop=$4
	read -d $'' VNCDESKTOP <<-EOE
		vncUSER=${username}
		vncPORT=${vncPORT}
		rfbport=${rfbport}
		DESKTOP=${desktop}
		    LOG=${LOG}
	EOE
}
function SET_VNCDESKTOP_OLD(){
	local username=$1
	local vncPORT=$2
	local rfbport=$3
	local desktop=$4
	read -d $'' VNCDESKTOP <<-EOE
		[vncUSER]=${username}
		[vncPORT]=${vncPORT}
		[rfbport]=${rfbport}
		[desktop]=${desktop}
	EOE
}
function VERIFY_GLOBAL_DESKTOP(){
	local username=$1
	local vncPORT=$2
	local wm=""
	 desktop=`echo ${desktop}  | tr A-Z a-z`
	DESKTOPS=`echo ${DESKTOPS} | tr A-Z a-z`
	# Match approved desktop type to GLOBAL variable desktops
	echo ' '${DESKTOPS}' ' | grep " ${desktop} " &>/dev/null && return 0
	#[[ "${DESKTOPS}" =~ (^|[[:space:]])"${desktop}"([[:space:]]|$) ]] && return 0
	# If no approved desktop is selected fix to default
	echo FIXING :: desktop selection from ${desktop:-MISSING}
	desktop='gnome'
	DISPLAY_WRITE_KEY ${username} ${vncPORT} desktop
}
function VERIFY_GLOBAL_RESOLUTION(){
	local username=$1
	local vncPORT=$2
	if ! [[ "${resolution}" =~ ^[0-9]+x[0-9]+$ ]]; then
		echo FIXING :: resolution format from ${resolution:-MISSING}
		resolution='1024x768'
		DISPLAY_WRITE_KEY ${username} ${vncPORT} resolution
	else
		local horz=${resolution%x*}
		local vert=${resolution#*x}
		local write_key=false
		(( horz < 640 ))  && horz=640  && write_key=true
		(( horz > 2048 )) && horz=2048 && write_key=true
		(( vert < 480 ))  && vert=480  && write_key=true
		(( vert > 2048 )) && vert=2048 && write_key=true
		if ${write_key}; then
			echo FIXING :: resolution range from ${resolution:-MISSING}
			resolution="${horz}x${vert}"
			DISPLAY_WRITE_KEY ${username} ${vncPORT} resolution
		fi
	fi
}
function VERIFY_GLOBAL_DEPTH(){
	local username=$1
	local vncPORT=$2
	if [[ "${depth}" =~ ^[0-9]*$ ]] &&\
	   (( depth != 8 && depth != 16 && depth != 24 )); then
		echo FIXING :: depth from ${depth:-MISSING}
		depth=16
		DISPLAY_WRITE_KEY ${username} ${vncPORT} depth
	fi
}
function VERIFY_UBUNTU_GNOME_LOGOUT(){
	local username=$1
	local desktop=$2
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local logout_desktop="${homedir}/Desktop/logout.desktop"
	# verify Ubuntu and gnome
	cat /etc/lsb-release | grep -i ubuntu &>/dev/null	&&\
	[ "${desktop}" == "gnome" ]				&&\
	cat <<-DESKTOP | su ${username} -c "tee \"${logout_desktop}\"" &>/dev/null
		#!/usr/bin/env xdg-open
		[Desktop Entry]
		Name=Gnome Session Logout
		GenericName=Logout
		Exec=/usr/bin/gnome-session-quit
		Icon=/usr/share/icons/Humanity/apps/48/gnome-session-logout.svg
		StartupNotify=true
		Terminal=false
		Type=Application
	DESKTOP
	chmod +x "${logout_desktop}"
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


# GLOBAL vars; import PATH config on Solaris machine
if IS_OS_SOLARIS; then
	export `grep ^PATH /etc/default/login`
fi

# GLOBAL vars; user display file
DISPLAY_FILE=".vnc/displays"

# set DEBUG to true for excessive function logging
DEBUG=true
DEBUG=false

# MAIN; setup or jump into vncserver session
main "$@" >> "${LOG}" 2>/dev/null

# Connect to vnc session
#cat | /opt/csw/bin/nc 127.0.0.1 ${rfbport} &
cat | NETCAT

# CLEANUP
rm -rf "${TMP}"
exit 0
