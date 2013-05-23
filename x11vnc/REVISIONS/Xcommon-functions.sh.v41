#!/bin/bash
function IS_USER_ADMIN(){
	local username=$1
	local vncPORT=$2
	shift 2
	GET_ALLOWED_USERS | grep -q "^${username}$"
}
function IS_USER_ALLOWED(){
	local username=$1
	local vncPORT=$2
	shift 2
        if ! GET_ALLOWED_USERS "$@" | grep -q "^${username}$"; then
                echo EXITING\!\!\! User \"${username}\" tried to\
                        VNC via $'('127.0.0.1:${vncPORT}$')'.
		return 1
        else
                echo "$@"              | xargs echo OPTARG :: 
                GET_ALLOWED_USERS "$@" | xargs echo ACCESS ::
		return 0
        fi
}
function GET_ALLOWED_USERS(){
	local entry=""
	local usernames=""
	local config_folder=$(readlink -nf "${BASH_SOURCE}")
	local config_folder=$(dirname "${config_folder}")
	# Append root to list of allowed users
	echo root
	# Append all users in the wheel group to allowed users
	PARSE_USERNAME wheel adm
	#echo _TEST_ :: ${config_folder} >> "${LOG}"
	for entry in "$@"; do
		if [ -f "${entry}" ]; then
			#echo _TEST_ :: is file >> "${LOG}"
			while read -a usernames; do
				PARSE_USERNAME "${usernames[*]}"
			done < <(cat "${entry}")
		elif [ -f "${config_folder}/${entry}" ]; then
			#echo _TEST_ :: is relative >> "${LOG}"
			while read -a usernames; do
				PARSE_USERNAME "${usernames[*]}"
			done < <(cat "${config_folder}/${entry}")
		else
			#echo _TEST_ :: is name >> "${LOG}"
			PARSE_USERNAME ${entry}
		fi
	done
}
function PARSE_USERNAME(){
	local username=""
	#echo _TEST_ :: PARSE - "$@" >> "${LOG}"
	for username in "$@"; do
		# if name is a username then add to list
		grep -q "^${username}:" /etc/passwd &> /dev/null && echo ${username}
		# parse groups for match and list users	
		cat <<-AWK | awk -F: -f <(cat) /etc/group
			\$1=="${username}" {
				gsub(" ","",\$4)	# remove all whitespace
				sub(/^,*/,"",\$4)	# remove leading commas
				sub(/,*\$/,"",\$4)	# remove trailing commas
				gsub(",","\n",\$4)	# sub commas for newlines
				if(\$4=="")exit		# exit if no users in group
				print \$4
				exit
			}
		AWK
	done
}
function GET_USER_HOMEDIR(){
	local username="$1"
	awk -F: -v USER=${username} '$1==USER{printf $6}' /etc/passwd
}
function GET_PROC_SOCKETS(){
	local process=$1
	local ss=$(which ss 2>/dev/null)
	[ -x "${ss}" ] || { echo BROKEN ?? The program \"ss\" could not be found\!; return 1; }
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
	local process=$1
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	echo ${sockets[0]%:*}
}
function GET_PROC_SRC_IP(){
	local process=$1
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	echo ${sockets[1]%:*}
}
function GET_PROC_DST_PORT(){
	local process=$1
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	echo ${sockets[0]#*:}
}
function GET_PROC_SRC_PORT(){
	local process=$1
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	echo ${sockets[1]#*:}
}
function GET_PROC_SRC_PID(){
	local process=$1
	local ss=$(which ss 2>/dev/null)
	[ -x "${ss}" ] || { echo BROKEN ?? The program \"ss\" could not be found\!; return 1; }
	local g='[[:graph:]]'			# sed graph key
	local p='[[:space:]]'			# sed white space key
	local -a sockets=( `GET_PROC_SOCKETS ${process}` )
	cat <<-SED | sed -n -f <(cat) <(${ss} -n -p src ${sockets[1]})
		s/.*${p}\+users:(("${g}\+",\([0-9]*\),.*/\1/p
	SED
}
function GET_PROC_SRC_UID(){
	local process=$1
	local srcPID=$(GET_PROC_SRC_PID ${process})
	ps --no-heading -o uid -p ${srcPID}
}
function GET_PROC_SRC_USER(){
	local process=$1
	local srcPID=$(GET_PROC_SRC_PID ${process})
	ps --no-heading -o user -p ${srcPID}
}
function GET_PROC_SRC_PPID(){
	local process=$1
	local srcPID=$(GET_PROC_SRC_PID ${process})
	ps --no-heading -o ppid -p ${srcPID}
}
