#!/bin/builder.sh

# IMPORTANT: Includes must be placed before global variables like "skip" & "step"
while read import; do
	${import:+/bin/bash} "${import:-false}"
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

# GLOBAL VARIABLES
skip=( false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

function setup_skel_Structure(){
	desc Build skel directory structure
	touch     /etc/skel/.toprc
	chmod 700 /etc/skel/.toprc
}
function setup_make_Config(){
	desc Setting up default config
	cat << END-OF-CONFIG > /etc/skel/.toprc
RCfile for "top with windows"           # shameless braggin'
Id:a, Mode_altscr=0, Mode_irixps=1, Delay_time=3.000, Curwin=0
Def     fieldscur=AEHIOQTWKNMbcdfgjplrsuvyzX
        winflags=32569, sortindx=10, maxtasks=0
        summclr=1, msgsclr=1, headclr=3, taskclr=1
Job     fieldscur=ABcefgjlrstuvyzMKNHIWOPQDX
        winflags=62777, sortindx=0, maxtasks=0
        summclr=6, msgsclr=6, headclr=7, taskclr=6
Mem     fieldscur=ANOPQRSTUVbcdefgjlmyzWHIKX
        winflags=62777, sortindx=13, maxtasks=0
        summclr=5, msgsclr=5, headclr=4, taskclr=5
Usr     fieldscur=ABDECGfhijlopqrstuvyzMKNWX
        winflags=62777, sortindx=4, maxtasks=0
        summclr=3, msgsclr=3, headclr=2, taskclr=3
END-OF-CONFIG
}
function setup_distribute_Config(){
	desc setting up default config \for existing users
	get_user_details all | while read user uid gid home; do
		su -m ${user} < <(cat << END-OF-CMDS
			cp "/etc/skel/.toprc" "${home}/."
			chmod 700 "${home}/.toprc"
END-OF-CMDS
)
	done
}
