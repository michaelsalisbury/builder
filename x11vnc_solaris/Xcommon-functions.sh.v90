#!/bin/bash
function IS_OS_SOLARIS(){
	uname | grep -i '^sunos$' &>/dev/null
}
function IS_OS_UBUNTU(){
	[ -f /etc/lsb-release ] &&\
	grep -i ubuntu /etc/lsb-release &>/dev/null
}
function IS_OS_REDHAT(){
	[ -f /etc/redhat-release ] && return 0 || return 1
}
function WHICH(){
	if IS_OS_SOLARIS; then
		which $1 2>/dev/null | grep -v "^no"
	else
		which $1 2>/dev/null
	fi
}
function DEBUGGER(){
	#${DEBUG:-true} && cat | xargs echo ${FUNCNAME[1]} ${1} >> "${LOG}"
	if ${DEBUG:-true}; then
		local DATA=""
		while read DATA; do
			echo "${DATA}" | xargs echo ${FUNCNAME[1]} ${1} >> "${LOG}"
		done < <(cat)
	fi
}
function IS_DOMAIN(){
	echo "$@" | DEBUGGER ??
	local object=$1
	id -u "${object}" &>/dev/null && ! IS_LOCAL_USER "${object}"
}
function GET_DOMAIN_TYPE(){
	echo "$@" | DEBUGGER ??
	local object=$1
	IS_DOMAIN "${object}" || return 1
	if which wbinfo &>/dev/null; then
		wbinfo -n "${object}" 2>/dev/null |
		awk '{print $2}' |
		awk -F_ '{print $NF}'
	elif getent initgroups "${object}" | grep -q -i "^${object}[[:space:]]*$"; then
		echo GROUP
	else
		echo USER
	fi
}
function IS_DOMAIN_USER(){
	echo "$@" | DEBUGGER ??
	local username=$1
	GET_DOMAIN_TYPE "${username}" |
	grep -q -i -x user
}
function IS_DOMAIN_GROUP(){
	echo "$@" | DEBUGGER ??
	local username=$1
	GET_DOMAIN_TYPE "${username}" |
	grep -q -i -x group
}
function IS_LOCAL_GROUP(){
	echo "$@" | DEBUGGER ??
	local group=$1
	! id -u "${group}" &>/dev/null && getent group "${group}" &>/dev/null
}
function IS_LOCAL_USER(){
	echo "$@" | DEBUGGER ??
	local username=$1
	getent shadow "${username}" &>/dev/null
}
function IS_USER_ADMIN(){
	echo "$@" | DEBUGGER ??
	local username=$1
	local vncPORT=$2
	shift 2

	grep -i -F -x -f <(GET_ALLOWED_ADMIN_USERS_GROUPS "$@") <(GET_USER_GROUPS "${username}") | xargs echo ACCESS ::
	if (( ${PIPESTATUS[0]} )); then	
		echo BASIC\  :: User \"${username}\" is NOT an admin\!
		return 1
	else
		echo SUPER\  :: User \"${username}\" is an admin\!
		return 0
	fi
}
function IS_USER_ALLOWED(){
	echo "$@" | DEBUGGER ??
	local username=$1
	local vncPORT=$2
	shift 2
	echo "$@" | xargs echo OPTARG :: 
	# compare lists "GET_ALLOWED_USERS_GROUPS,GET_USER_GROUPS" to see if there is a match between them
	grep -i -F -x -f <(GET_ALLOWED_USERS_GROUPS "$@") <(GET_USER_GROUPS "${username}") | xargs echo ACCESS ::
	if (( ${PIPESTATUS[0]} )); then	
                echo EXITING\!\!\! User \"${username}\" tried to\
                        VNC via $'('127.0.0.1:${vncPORT}$')'.
		return 1
        fi
}
function GET_USER_GROUPS(){
	echo "$@" | DEBUGGER ??
	local GID username=$1
	# domain groups if queried via group can hang due to the masive number of members
	# domain groups are assumed to have a matching user with the same ID
	IS_LOCAL_USER "${username}" && local DB='group' || local DB='passwd'
	# echo the username
	getent passwd "${username}" 2>/dev/null | cut -d: -f1
	# generate a list of groups the user is a memebr off
	for GID in `id -G "${username}" 2>/dev/null`; do
		getent ${DB} ${GID} 2>/dev/null | cut -d: -f1
	done
}
function GET_ALLOWED_ADMIN_USERS_GROUPS(){
	GET_ALLOWED_USERS_GROUPS "$@"
}
function GET_ALLOWED_USERS_GROUPS(){
	echo "$@" | DEBUGGER ??
	local arg=""		# loop var
	local object=""	# loop var
	local config_folder=${CONFIG_FOLDER}
	local admin_indicator='*'

	# Append root to list of allowed users
	echo root
	# arguments supplied to this function are either users and groups or a file with a list of users or groups
	for arg in "$@"; do
		if [ -f "${arg}" ]; then
			cat "${arg}"
		elif [ -f "${config_folder}/${arg}" ]; then
			cat "${config_folder}/${arg}"
		else
			echo "${arg}"
		fi
	done |
	while read object; do
		# remove blank or commane lines
		[[ "${object}" =~ ^[[:space:]]*('#'|$) ]] && continue
		# strip leading and trailing spaces
		[[ "${object}" =~ ^[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] && object=${BASH_REMATCH[1]}
		# strip trailing admin indicator character
		[[ "${object}" =~ (.*[^[:space:]])[[:space:]]*[${admin_indicator}]$ ]] && object=${BASH_REMATCH[1]} IS_ADMIN=true || IS_ADMIN=false
		# skip users/groups who arn't admins
		case "${FUNCNAME[1]}" in
			GET_ALLOWED_ADMIN_USERS_GROUPS) ${IS_ADMIN} || continue;;
		esac
		# print allowed users/groups
		echo "${object}"

	done |
	IS_USER_GROUP
}
function IS_USER_GROUP(){
	echo "$@" | DEBUGGER ??
	while read object; do
		if IS_LOCAL_USER "${object}"; then
			local DB='passwd'
		elif IS_LOCAL_GROUP "${object}" || IS_DOMAIN_USER "${object}"; then
			local DB='group'
		else
			local DB='passwd'
		fi
		getent ${DB} "${object}" 2>/dev/null | cut -d: -f1 
	done < <((( ${#1} )) && echo "${object}" || cat)
	# this returns the status of the last iteration of the getent command
	# generally the exit status is not important unless only one object is being tested
	return ${PIPESTATUS[0]}
}
function GET_USER_HOMEDIR(){
	echo "$@" | DEBUGGER ??
	local username="$1"
	#cat <<-AWK | awk -F: -f <(cat) /etc/passwd <(which wbinfo &>/dev/null && wbinfo -i "${username}" 2>/dev/null) | tee >(DEBUGGER ==)
	cat <<-AWK | awk -F: -f <(cat) <(getent passwd "$(id -u "${username}" 2>/dev/null)") | tee >(DEBUGGER ==)
		\$1=="${username}"{print \$6}
	AWK
}
function GET_PROC_SOCKETS(){
	echo "$@" | DEBUGGER ??
	local process=$1
	if (( ${#SOCKETS[*]} > 0 )); then
		echo ${SOCKETS[*]} | tee >(DEBUGGER ==)
	else
		local lsof=$(which lsof 2>/dev/null)	
		[ -x "${lsof}" ] ||\
		{ echo BROKEN ?? The program \"lsof\" could not be found\!; return 1; }
		local LINE=""
		while read -a LINE; do
			case ${LINE:0:1} in
				n)	SOCKETS=( ${LINE//[\-\>n]/ } )
					break;;
			esac
		done < <( 
			${lsof} -n -P			\
				-p ${process}		\
				-a			\
				-c ${BASH_SRCNAME}	\
				-a			\
				-i			\
				-F n
			)
		echo ${SOCKETS[*]} | tee >(DEBUGGER ==)
	fi
}
function GET_PROC_SOCKETS_OLD(){
	echo "$@" | DEBUGGER ??
	local process=$1
	local ss=$(which ss 2>/dev/null)
	[ -x "${ss}" ] ||\
	{ echo BROKEN ?? The program \"ss\" could not be found\!; return 1; }
	local ocket='\([0-9\.\*]\+:[0-9\*]\+\)'	# sed socket filter
	local p='[[:space:]]\+'			# sed white space key
	cat <<-SED | sed -n -f <(cat) <(${ss} -np)
		/,${process},/{
			s/.*$p$ocket$p$ocket$p.*/\1 \2/
			p
		}
	SED
}
function GET_PROC_DST_IP(){
	echo "$@" | DEBUGGER ??
	local process=$1
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	echo ${sockets[0]%:*}
}
function GET_PROC_SRC_IP(){
	echo "$@" | DEBUGGER ??
	local process=$1
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	echo ${sockets[1]%:*}
}
function GET_PROC_DST_PORT(){
	echo "$@" | DEBUGGER ??
	local process=$1
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	echo ${sockets[0]#*:}
}
function GET_PROC_SRC_PORT(){
	echo "$@" | DEBUGGER ??
	local process=$1
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	echo ${sockets[1]#*:}
}
function GET_PROC_SRC_PID(){
	echo "$@" | DEBUGGER ??
	local process=$1
	if (( ${#SRCPID} > 0 )); then
                echo ${SRCPID} | tee >(DEBUGGER ==)
        else
		local lsof=$(which lsof 2>/dev/null)
		[ -x "${lsof}" ] ||\
		{ echo BROKEN ?? The program \"lsof\" could not be found\!; return 1; }
		local -a sockets=( `GET_PROC_SOCKETS ${process}` )
		local LINE=""
		while read LINE; do
			case ${LINE:0:1} in
				p)	SRCPID=${LINE:1};;
				u)	SRCUID=${LINE:1};;
			esac
		done < <(
			${lsof} -n -P			\
				-p ^${process}		\
				-a			\
				-c sshd			\
				-a			\
				-i TCP@${sockets[1]}	\
				-F pu
		)
		echo ${SRCUID} | DEBUGGER ==
                echo ${SRCPID} | tee >(DEBUGGER ==)
	fi
}
function GET_PROC_SRC_PID_OLD(){
	echo "$@" | DEBUGGER ??
	local process=$1
	local ss=$(which ss 2>/dev/null)
	[ -x "${ss}" ] ||\
	{ echo BROKEN ?? The program \"ss\" could not be found\!; return 1; }
	local g='[[:graph:]]'			# sed graph key
	local p='[[:space:]]'			# sed white space key
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	cat <<-SED | sed -n -f <(cat) <(${ss} -n -p src ${sockets[1]})
		s/.*${p}\+users:(("${g}\+",\([0-9]*\),.*/\1/p
	SED
}
function GET_PROC_SRC_UID(){
	echo "$@" | DEBUGGER ??
	local process=$1
	if (( ${#SRCUID} > 0 )); then
		echo ${SRCUID} | tee >(DEBUGGER ==)
	else
		local srcPID=$(GET_PROC_SRC_PID ${process})
		SRCUID=`ps -o uid -p ${srcPID} | sed '1d'`
		echo ${SRCUID} | tee >(DEBUGGER ==)
	fi
}
function GET_PROC_SRC_USER(){
	echo "$@" | DEBUGGER ??
	local process=$1
	if (( ${#SRCUSER} > 0 )); then
		echo ${SRCUSER} | tee >(DEBUGGER ==)
	else
		local srcPID=$(GET_PROC_SRC_PID ${process})
		SRCUSER=`ps -o user -p ${srcPID} | sed '1d'`
		echo ${SRCUSER} | tee >(DEBUGGER ==)
	fi
}
function GET_PROC_SRC_PPID(){
	echo "$@" | DEBUGGER ??
	local process=$1
	if (( ${#SRCPPID} > 0 )); then
		echo ${SRCPPID} | tee >(DEBUGGER ==)
	else
		local srcPID=$(GET_PROC_SRC_PID ${process})
		SRCPPID=`ps -o ppid -p ${srcPID} | sed '1d'`
		echo ${SRCPPID} | tee >(DEBUGGER ==)
	fi
}
function DISPLAY_NEW(){
	# Utilizes GLOBAL vars; DISPLAY_FILE
	local username="$1"
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	su ${username} -s /bin/bash <<-SU
		touch     "${displays}"
		chmod 600 "${displays}"
	SU
}
function DISPLAY_NEW_PORT(){
	# Utilizes GLOBAL vars; DISPLAY_FILE
	echo "$@" | DEBUGGER ??
	local username="$1"
	local vncPORT="$2"
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	# setup file if missing
	[ -f "${displays}" ] || DISPLAY_NEW "${username}"
	# append new port entry to the end of file
	grep "^\[${vncPORT}]" "${displays}" &>/dev/null ||\
	echo "[${vncPORT}]" >> "${displays}"
	cat "${displays}" | DEBUGGER %%
}
function DISPLAY_READ_KEYS(){
	# Utilizes GLOBAL vars; DISPLAY_FILE
	echo "$@" | DEBUGGER ??
	local username="$1"
	local vncPORT="$2"
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	local vncfolder=$(dirname "${displays}")
	local fifo_IN="${TMP}/${FUNCNAME}_FIFO-IN"
	local fifo_OUT="${TMP}/${FUNCNAME}_FIFO-OUT"
	# setup missing ~/.vnc folder
	[ -d "${vncfolder}" ] ||\
		su - ${username} <<-SU
			mkdir -p "${vncfolder}"
		SU
	# setup file if missing
	[ -f "${displays}" ] ||\
		DISPLAY_SETUP_DEFAULTS ${username} ${vncPORT}
	# if port entry is missing 
	grep "^\[${vncPORT}]" "${displays}" &>/dev/null ||\
		DISPLAY_SETUP_DEFAULTS ${username} ${vncPORT}
	# setup fifo and dd buffer
	mkfifo "${fifo_IN}"    "${fifo_OUT}" 2>/dev/null
	dd  if="${fifo_IN}" of="${fifo_OUT}" 2>/dev/null &
	# read entry values
	#cat <<-SED | sed -n -f <(cat) "${displays}" | tee "${fifo_IN}"
	cat <<-SED | sed -n -f <(cat) "${displays}" >> "${fifo_IN}" 
		/^\[${vncPORT}]/,/^\[/{
			/^[^\[]/p
		}
	SED
	local LINE=""
	while read LINE; do eval ${LINE}; done < "${fifo_OUT}"
}
function DISPLAY_SETUP_DEFAULTS(){
	# Utilizes GLOBAL vars; DISPLAY_FILE
	echo "$@" | DEBUGGER ??
	local username="$1"
	local vncPORT="$2"
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	local fifo_IN="${TMP}/${FUNCNAME}_FIFO-IN"
	local fifo_OUT="${TMP}/${FUNCNAME}_FIFO-OUT"
	# setup file if missingi & add port entry
	DISPLAY_NEW_PORT ${username} ${vncPORT}
	# setup default key value pairs
	local desktop='mate'
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
	done
	# setup fifo and dd buffer
	mkfifo "${fifo_IN}"    "${fifo_OUT}" 2>/dev/null
	dd  if="${fifo_IN}" of="${fifo_OUT}" 2>/dev/null &
	# remove any blank lines
	cat <<-SED | sed -f <(cat) "${displays}" >> "${fifo_IN}"
		/^\[${vncPORT}]/,/^\[/{
			 /^$/d
		}
	SED
	# Write changes back to source display file
	cat "${fifo_OUT}" > "${displays}"
}
function DISPLAY_WRITE_KEY(){
	# Utilizes GLOBAL vars; DISPLAY_FILE
	local username="$1"
	local vncPORT="$2"
	local key="$3"
	local value=${!key}
	local homedir=$(GET_USER_HOMEDIR "${username}")
	local displays="${homedir}/${DISPLAY_FILE}"
	local TAB=$'	'
	local SPACE=$' '
	local fifo_IN="${TMP}/${FUNCNAME}_FIFO-IN"
	local fifo_OUT="${TMP}/${FUNCNAME}_FIFO-OUT"
	# setup file if missing
	[ ! -f "${displays}" ] &&\
		DISPLAY_NEW "${username}"
	# if port entry is missing
	! grep "^\[${vncPORT}]" "${displays}" &>/dev/null &&\
		DISPLAY_NEW_PORT ${username} ${vncPORT}

	# setup fifo and dd buffer
	mkfifo "${fifo_IN}"    "${fifo_OUT}" 2>/dev/null
	dd  if="${fifo_IN}" of="${fifo_OUT}" 2>/dev/null &

	# test if key value pair exists then edit
	if cat <<-SED | sed -n -f <(cat) "${displays}" | grep ".*" &>/dev/null; then
			/^\[${vncPORT}]/,/^\[/{
				/^[${TAB}${SPACE}]*${key}=/p
			}
		SED
		cat <<-SED | sed -f <(cat) "${displays}" >> "${fifo_IN}"
			/^\[${vncPORT}]/,/^\[/{
				/^[${TAB}${SPACE}]*${key}=/{
					s/=.*/=${value}/
				}
			}
		SED
	# if the keyvalue pair does not exist then append to the end of the entries
	elif cat <<-SED | sed -f <(cat) "${displays}" | grep ".*" &>/dev/null; then
			/^\[${vncPORT}]/,/^\[/{
				/^\[${vncPORT}]/d
				/^\[/p
			}
			d
		SED
		cat <<-SED | sed -f <(cat) "${displays}" >> "${fifo_IN}"
			/^\[${vncPORT}]/,/^\[/{
				/^\[${vncPORT}]/b
				/^\[/i\\
				${TAB}${key}=${value}
			}
		SED
	else
		cat <<-SED | sed -f <(cat) "${displays}" >> "${fifo_IN}"
			/^\[${vncPORT}]/,/^\[/{
				\$ a\\
				${TAB}${key}=${value}
			}
		SED
	fi
	# Write changes back to source display file
	cat "${fifo_OUT}" > "${displays}"
}

