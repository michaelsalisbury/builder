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
function GET_DISPLAY_0_USER(){
	# get user logged into disaply ${DISPLAY}, DEFAULTS to :0
	#echo localcosadmin
	#return
	who -u |\
	awk '/ tty[0-9].* \(:0\)/{print $1}' |\
	tee -a >(${DEBUG} && xargs echo ${FUNCNAME} :: >> "${LOG}") |\
	grep ""
	(( $? > 0 )) && { echo ERROR \"${FUNCNAME}\" >> "${LOG}"; EXIT 1; }
}
