#!/bin/bash
#https://wiki.archlinux.org/index.php/X11vnc
LOG=/var/log/x11vnc.dynamic
XvncPORT=5901

function testPIPE(){
	local PORT=$1
	cat | /usr/bin/nc 127.0.0.1 ${PORT} &
	local ncPID=$!
	(	echo netcatPID :: ${ncPID}
		echo Xvnc PORT :: ${PORT}
	) >> "${LOG}"
}
#cat | testPIPE ${XvncPORT}
#exit 0


function main(){
	echo -------------------------------------------------------- `date "+%Y.%m.%d-%T"`
	
	echo srvARGS : "$@"
	echo x11PID :: $$
	echo x11PPID : $PPID
	echo x11prog : $(basename "${BASH_SOURCE}")

	# get sockets
	local ock='\([0-9\.]\+:[0-9]\+\)'	# sed socket filter
	local p='[[:space:]]'			# sed white space key
	# "/,$$,/s/.*[[:s:]]\([0-9\.]\+:[0-9]\+\)[[:s:]]*\([0-9\.]\+:[0-9]\+\)[[:s:]].*/p;d"
	local -a sockets=($(ss -np | sed "/,$$,/s/.*$p$ock$p*$ock$p.*/\1 \2/p;d"))
	local dstIP=${sockets[0]%:*}
	local dstPORT=${sockets[0]#*:}
	local srcIP=${sockets[1]%:*}
	local srcPORT=${sockets[1]#*:}
	
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

	# setup desktop name for re-connecting
	local desktop=${srcUSER}_${dstPORT}

	# get display number
	local dispNUM=$(( dstPORT - 6049 ))

	# get display details
	local dispOPT=($(/bin/su -l ${srcUSER} -c "/bin/sed '/^${dispNUM}[[:space:]]/p;d' ~/.vnc/map"))

	# 

	# get last display NUM
	local 




	echo dispNUM : ${dispNUM}
	echo d sock :: ${sockets[0]}
	echo d IPAD :: ${dstIP}
	echo d PORT :: ${dstPORT}
	echo s sock :: ${sockets[1]}
	echo s IPAD :: ${srcIP}
	echo s PORT :: ${srcPORT}
	
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
	echo

	# test if connecting user was not on the allowed_users array list
	if ! $(IFS=$'\n'; echo "${allowed_users[*]}" | grep -q "^${srcUSER}$"); then
		ERROR_MSG User [${srcUSER}] tried to VNC via $'\('${sockets[0]}$')'. &
		echo EXITING\!\!\! User \"${srcUSER}\" tried to\
			VNC via $'('${sockets[0]}$')'.
	fi

	



	return 0

	cat << END-OF-VNCSERVER-SETUP | su ${srcUSER}
		/usr/bin/vncserver		\
			-name ${desktop}	\
			-autokill		\
			-SecurityTypes None	\
			-localhost		\
			-rfbport ${dstPORT}
END-OF-VNCSERVER-SETUP

			#-geometry 1024x768	\
			#-depth 16		\

	

}
function ERROR_MSG(){
	local dlgTEXT="$@"
	local user_logged_into_DISPLAY0=$(who -u | awk '/tty7.*\(:0/{print $1}')
	local dlgOPTS=(
		--error
		--timeout=15
		--title=\"Remote user attempting connection: ALLERT\"
		--text=\"${dlgTEXT}\"
	)
	/bin/su ${user_logged_into_DISPLAY0} -c "DISPLAY=:0 zenity ${dlgOPTS[*]}"
	echo ERROR_MSG :: returned $? :: ${dlgTEXT}
}

#main "$@" 2>&1 >> "${LOG}"
main "$@" >> "${LOG}"

cat | testPIPE ${XvncPORT}
exit 0

