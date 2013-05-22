#!/bin/bash
#https://wiki.archlinux.org/index.php/X11vnc
DISPLAY_FILE=".vnc/displays"
DESKTOPS='gnome twm ice fluxbox xfce4 kde'
CONFIG_FOLDER=$(readlink -nf "${BASH_SOURCE}")
CONFIG_FOLDER=$(dirname "${CONFIG_FOLDER}")
source "${CONFIG_FOLDER}/Xcommon-functions.sh"
LOG=/var/log/Xvnc-dynamic
touch     "${LOG}"
chmod 777 "${LOG}"

function main(){
	echo ----------------------------------------- `date "+%Y.%m.%d-%T"`
	
	echo ___GET :: src USER :: `GET_PROC_SRC_USER $$`
	echo ___GET :: src PID_ :: `GET_PROC_SRC_PID $$`
	echo ___GET :: src PORT :: `GET_PROC_SRC_PORT $$`
	echo ___GET :: vnc PORT :: `GET_PROC_DST_PORT $$`
	echo

	# get connecting username
	local srcUSER=`GET_PROC_SRC_USER $$`
	local vncPORT=`GET_PROC_DST_PORT $$`
	local usrHOME=`GET_USER_HOMEDIR ${srcUSER}`

	# test if connecting user was not on the allowed_users array list
	IS_USER_ALLOWED ${srcUSER} ${vncPORT} "$@" || exit 1
	IS_USER_ADMIN   ${srcUSER} && echo ACCESS :: User is Admin

	# load last known display port details (bewaire; these will be global)
	DISPLAY_READ_KEYS ${srcUSER} ${vncPORT}
	
	# verify that desktop selection is supported
	VERIFY_GLOBAL_DESKTOP ${srcUSER} ${vncPORT}

	# verify resolution is formatted correctly and in range
	VERIFY_GLOBAL_RESOLUTION ${srcUSER} ${vncPORT}

	# verify that depth is a positive integer
	# verify that depth is only values of 8, 16 & 24 (15 has font problems)
	VERIFY_GLOBAL_DEPTH ${srcUSER} ${vncPORT}

	# echo vncserver setup details
	echo GLOBAL :: ________________________
        echo GLOBAL :: resolution :: ${resolution}
        echo GLOBAL :: ____ depth :: ${depth}
        echo GLOBAL :: __ desktop :: ${desktop}

	# test to see if display is still open 
	if ! IS_DISPLAY_OPEN ${srcUSER} ${vncPID} ${vncDisplay}; then
		# generate randome port number to create vncserver display
		SET_FREE_LISTENING_PORT ${srcUSER} ${vncPORT}
		# write xstartup file
		SET_xstartup ${srcUSER}
		# setup vncserver display port
		cat <<-END-OF-VNCSERVER-SETUP | su ${srcUSER} -s /bin/bash
			cd "${usrHOME}"
			/usr/bin/vncserver		\
				-autokill		\
				-SecurityTypes None	\
				-localhost		\
				-httpPort 0		\
				-nolisten tcp		\
				-geometry ${resolution}	\
				-depth ${depth}		\
				-rfbport ${rfbport} 2>&1
		END-OF-VNCSERVER-SETUP
				#-NeverShared		\

		# write new vncPID key to display file
		SET_vncPID ${srcUSER} ${vncPORT}
		# write new vncDisplay key to display file
		SET_vncDisplay ${srcUSER} ${vncPORT}
	else
		echo _JUMP_ ::
	fi

	# echo vncserver connection details
	echo GLOBAL :: ________________________
	echo GLOBAL :: __ rfbport :: ${rfbport}
	echo GLOBAL :: ___ vncPID :: ${vncPID}
        echo GLOBAL :: vncDisplay :: ${vncDisplay}
	echo
}
function NETCAT(){
	local nc=$(which nc 2>/dev/null)
	[ -x "${nc}" ] || { echo BROKEN ?? The program \"nc\" could not be found\!; return 1; }
	cat | ${nc} 127.0.0.1 ${rfbport} &
	echo NETCAT :: sshTunnel PID :: $! >> "${LOG}"
}
function DISPLAY_NEW(){
	local username="$1"
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	cat <<-SU | su ${username} -s /bin/bash
		touch     "${displays}"
		chmod 600 "${displays}"
	SU
}
function DISPLAY_NEW_PORT(){
	local username="$1"
	local vncPORT="$2"
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	# setup file if missing
	[ -f "${displays}" ] || DISPLAY_NEW "${username}"
	# append new port entry to the end of file
	grep -q "^\[${vncPORT}]" "${displays}" || echo "[${vncPORT}]" >> "${displays}"
}
function DISPLAY_READ_KEYS(){
	local username="$1"
	local vncPORT="$2"
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	# setup file if missing
	[ -f "${displays}" ] || DISPLAY_SETUP_DEFAULTS ${username} ${vncPORT}
	# if port entry is missing 
	grep -q "^\[${vncPORT}]" "${displays}" || DISPLAY_SETUP_DEFAULTS ${username} ${vncPORT}
	# read entry values
	source <(
		cat <<-SED | sed -n -f <(cat) "${displays}"
			/^\[${vncPORT}]/,/^\[/{
				/^[^\[]/p
			}
		SED
	)
}
function DISPLAY_SETUP_DEFAULTS(){
	local username="$1"
	local vncPORT="$2"
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	# setup file if missingi & add port entry
	DISPLAY_NEW_PORT ${username} ${vncPORT}
	# setup default key value pairs
	local desktop='gnome'
	local resolution='1024x768'
	local depth='15'
	local rfbport='0'
	local vncDisplay='0'
	local vncPID='0'
	local name="none"
	local key=""
	# write key value pairs
	for key in desktop resolution depth rfbport vncDisplay vncPID name; do
		DISPLAY_WRITE_KEY ${username} ${vncPORT} ${key}
		sleep .3
	done
	# remove any blank lines
	cat <<-SED | sed -i -f <(cat) "${displays}"
		/^\[${vncPORT}]/,/^\[/{
			 /^$/d
		}
	SED
}
function DISPLAY_WRITE_KEY(){
	local username="$1"
	local vncPORT="$2"
	local key="$3"
	local value=${!key}
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	# setup file if missing
	[ ! -f "${displays}" ] && DISPLAY_NEW "${username}"
	# if port entry is missing
	! grep -q "^\[${vncPORT}]" "${displays}" && DISPLAY_NEW_PORT ${username} ${vncPORT}
	# test if key value pair exists then edit
	if cat <<-SED | sed -f <(cat) "${displays}" | grep -q ""; then
			/^\[${vncPORT}]/,/^\[/{
				/^[[:space:]]*${key}=/p
			}
			d
		SED
		cat <<-SED | sed -i -f <(cat) "${displays}"
			/^\[${vncPORT}]/,/^\[/{
				/^[[:space:]]*${key}=/{
					s/=.*/=${value}/
				}
			}
		SED
	# if the keyvalue pair does not exist then append to the end of the entries
	elif cat <<-SED | sed -f <(cat) "${displays}" | grep -q ""; then
			/^\[${vncPORT}]/,/^\[/{
				/^\[${vncPORT}]/d
				/^\[/p
			}
			d
		SED
		cat <<-SED | sed -i -f <(cat) "${displays}"
			/^\[${vncPORT}]/,/^\[/{
				/^\[${vncPORT}]/b
				/^\[/i\\\t${key}=${value}
			}
		SED
	else
		cat <<-SED | sed -i -f <(cat) "${displays}"
			/^\[${vncPORT}]/,/^\[/{
				\$a\\\t${key}=${value}
			}
		SED
	fi
}
function IS_DISPLAY_OPEN(){
	local username=$1
	local vncPID=$2
	local display=$3
	local homedir=$(GET_USER_HOMEDIR "${username}")
	#grep -q "^${vncPID}$" "${homedir}/.vnc/"*":${display}.pid" 2>&1 >> "${LOG}"
	grep -q "^${vncPID}$" "${homedir}/.vnc/"*":${display}.pid" &> /dev/null
}
function SET_vncPID(){
	local username=$1
	local vncPORT=$2
	local ss=$(which ss 2>/dev/null)
	[ -x "${ss}" ] || { echo BROKEN ?? The program \"ss\" could not be found\!; return 1; }
	# if no listening port with process command Xvnc then fail
	grep -q "127.0.0.1:${rfbport}.*Xvnc" <(${ss} -atnp) || \
	{ echo ERROR :: SET_vncPID failed.; return 1; }
	# get vncPID 
	vncPID=$(	
		cat <<-SED | sed -n -f <(cat) <(${ss} -atnp)
			/127.0.0.1:${rfbport}/{
				s/[()\"[:space:]]\+//g
				s/.*Xvnc,\([0-9]*\),.*/\1/p
			}
		SED
	)
	# write vncPID key to display file
	DISPLAY_WRITE_KEY ${username} ${vncPORT} vncPID
}
function SET_vncDisplay(){
	local username=$1
	local vncPORT=$2
	local homedir=$(GET_USER_HOMEDIR "${username}")
	# if pid file missing then fail
	grep -q "${vncPID}" "${homedir}"/.vnc/*.pid || \
	{ echo ERROR :: SET_vncDisplay failed.; return 1; }
	# get vncDisplay
	local vncPID_file=$(grep -l "${vncPID}" "${homedir}"/.vnc/*.pid)
	vncDisplay=$(basename "${vncPID_file}" .pid)
	vncDisplay=${vncDisplay#*:}
	# write vncDisplay key to display file
	DISPLAY_WRITE_KEY ${username} ${vncPORT} vncDisplay
}
function SET_xstartup(){
	local username=$1
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local XsCustom="${CONFIG_FOLDER}/xstartup"
	local xstartup="${homedir}/.vnc/xstartup"
	local xdesktop="${homedir}/.vnc/xstartup.${rfbport}"
	# setup the prefered desktop
	cat <<-xstartup > "${xdesktop}"
		${desktop}
	xstartup
	# if .Xclients exists and is diff then 
	if [ -f "${xstartup}" ] && ! \
	   diff "${xstartup}" "${XsCustom}" &> /dev/null; then
		# if xstartup has already been backed-up then date stamp
		if find "${xstartup}".user* &> /dev/null; then
			mv -f "${xstartup}" "${xstartup}".user_$(date "+%s")
		else
			mv -f "${xstartup}" "${xstartup}".user
		fi
	fi
	# setup the custom xstartup file
	cat <<-SU | su ${username} -s /bin/bash
		cp -f "${XsCustom}" "${xstartup}"
		chmod +x            "${xstartup}"
	SU
}
function SET_xstartup_old(){
	local username=$1
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local config_folder=$(readlink -nf "${BASH_SOURCE}")
	local config_folder=$(dirname "${config_folder}")
	local Xclients="${config_folder}/Xclients"
	local xstartup="${homedir}/.vnc/xstartup.${rfbport}"
	# setup the prefered desktop
	cat <<-xstartup > "${xstartup}"
		${desktop}
	xstartup
	# if .Xclients exists and is diff then 
	if [ -f "${homedir}/.Xclients" ] && ! \
	   diff "${homedir}/.Xclients" "${Xclients}" &> /dev/null; then
		mv -f "${homedir}/.Xclients" "${homedir}/.Xclients.user"
	fi
	# setup the custom .Xclients file
	cat <<-SU | su ${username} -s /bin/bash
		cp -f "${Xclients}" "${homedir}/.Xclients"
		chmod +x            "${homedir}/.Xclients"
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
function VERIFY_GLOBAL_DESKTOP(){
	local username=$1
	local vncPORT=$2
	local wm=""
	 desktop=`echo ${desktop}  | tr A-Z a-z`
	DESKTOPS=`echo ${DESKTOPS} | tr A-Z a-z`
	# Match approved desktop type to GLOBAL variable desktops
	[[ "${DESKTOPS}" =~ (^|[[:space:]])"${desktop}"([[:space:]]|$) ]] && return 0
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
main "$@" >> "${LOG}"
cat | NETCAT
exit 0
