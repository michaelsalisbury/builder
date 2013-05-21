#!/bin/bash

LOG=/var/log/x11vnc.helper

function main(){
	echo -------------------------------------------------------- `date "+%Y.%m.%d-%T"`

	user_logged_into_DISPLAY0=$(who -u | awk '/tty7.*\(:0/{print $1}')
	echo USER :: ${user_logged_into_DISPLAY0}

	if [ -n "${user_logged_into_DISPLAY0}" ]; then
		su ${user_logged_into_DISPLAY0} \
			-c "DISPLAY=:0 gnome-screensaver-command -d"
	fi
}

main "$@" 2>&1 >> "${LOG}"
exit 0
