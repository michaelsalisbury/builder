#!/bin/bash
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
function FIND_PID(){
	local ppid=$1
	local cmd=$2
	local pid=""
	ps --no-heading -o pid --ppid ${ppid} &>/dev/null || return 0
	# test child pids for command match
	# ps --no-heading -fp ${ppid} >> "${LOG}"
	while read pid; do
		if ps --no-heading -o cmd -p ${pid} | grep -q "^${cmd}"; then
			echo ${pid}
			return 0
		fi
	done < <(ps --no-heading -o pid --ppid ${ppid})
	# if no command match found then process children 
	while read pid; do
		${FUNCNAME} ${pid} ${cmd}
	done < <(ps --no-heading -o pid --ppid ${ppid})
}
function GET_DISPLAY_USER(){
	echo xubuntu
	return 0
	# Dependant on function LOG and GLOBAL var DEBUG
	local DISPLAY_NUM=${1:-0}
	local DISPLAY_NUM=${DISPLAY_NUM//[^0-9.]/}
	#grep "[[:space:]]tty[0-9][[:space:]].*(:${DISPLAY_NUM}\(\.0\)\?)" 
	who -u |\
	grep "[[:space:]]\(tty\|pts/\)[0-9]\+[[:space:]].*(:${DISPLAY_NUM}\(\.0\)\?)" |\
	awk '{print $1}' |\
	sort -u |\
	tee >(LOG ${DEBUG:-false} DEBUG :: ${FUNCNAME} :: DISPLAY_NUM = ${DISPLAY_NUM} ::) |\
	grep ""
	# this last line returns false to the calling function if no user found
}
function GET_USER_HOME_DIR(){
	if (( ${#1} > 0 )); then
		local USERNAME=$1
	else
		LOG ERROR :: ${FUNCNAME} :: USERNAME not supplied.
		EXIT 1
	fi
	cat <<-AWK | awk -F: -f <(cat) /etc/passwd |\
	tee >(LOG ${DEBUG:-false} DEBUG :: ${FUNCNAME} :: USERNAME = ${USERNAME} ::) |\
	grep ""
		\$1=="${USERNAME}"{print \$6}
	AWK
	(( $? )) && LOG ERROR :: ${FUNCNAME} :: USERNAME = \"${USERNAME}\", No home dir. && EXIT 1
}
function IS_DEVICE_REAL(){
	local DEV=${DEVICE:-$1}
	local DEV=${1:-${DEV}}
	if ! GET_DEVICE_LIST | grep -q "^${DEV}$"; then
		echo ERROR :: ${FUNCNAME} :: Device \"${DEV}\" is not real or not attached. Exiting\! 1>&2
		EXIT 1
	fi
}
function GET_ROOT_DEVICE(){
	#awk '/[[:space:]]\/[[:space:]]/{print $1}' /etc/mtab |\
	awk '/ \/ /{print $1}' /etc/mtab |\
	xargs basename |\
	tr -d '0-9' |\
	grep ""
	if (( $? > 0 )); then
		echo ERROR :: ${FUNCNAME} :: Could not determine host system ROOT disk. Exiting\! 1>&2
		EXIT 1
	fi
}
function GET_DEVICE_LIST(){
	local ROOT=$(GET_ROOT_DEVICE)
	ls -1 /dev/sd[a-z] |\
	awk -F/ -v ROOT=${ROOT} '$3!=ROOT{print $3}' |\
	grep ""
	if (( $? > 0 )); then
		echo ERROR :: ${FUNCNAME} :: No attached non-root devices. Exiting\! 1>&2
		EXIT 1
	fi
}
function IS_DEVICE_ROOT(){
	local DEV=${1:-${DEVICE}}
	if GET_ROOT_DEVICE | grep -q "^${DEV}$"; then
		echo ERROR :: ${FUNCNAME} :: Device \"${DEV}\" is host system ROOT disk.  Exiting\! 1>&2
		EXIT 1
	fi
}
