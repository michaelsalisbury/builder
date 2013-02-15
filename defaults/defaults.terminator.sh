#!/bin/builder.sh
skip=( false false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

while read import; do
	. "${import}"
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

function setup_skel_Structure(){
	desc Build skel directory structure
	mkdir -p  /etc/skel/.config/terminator
	chmod 700 /etc/skel/.config
	chmod 700 /etc/skel/.config/terminator
}
function setup_make_Config(){
	desc Setting up default config
	cat << END-OF-CONFIG > /etc/skel/.config/terminator/config
[global_config]
[keybindings]
[profiles]
  [[default]]
    copy_on_selection = True
    use_system_font = False
    font = Monospace 14
    scrollbar_position = hidden
    scrollback_infinite = True
    login_shell = True
[layouts]
  [[Deploy]]
    [[[child0]]]
      position = 2113:155
      type = Window
      order = 0
      parent = ""
      size = 1855, 1056
    [[[child1]]]
      position = 614
      type = VPaned
      order = 0
      parent = child0
    [[[child2]]]
      position = 927
      type = HPaned
      order = 0
      parent = child1
    [[[child5]]]
      position = 927
      type = HPaned
      order = 1
      parent = child1
    [[[terminal3]]]
      profile = default
      type = Terminal
      order = 0
      parent = child2
      title = cmd
      command = 'cd /root/deploys; /bin/bash -l'
    [[[terminal4]]]
      profile = default
      type = Terminal
      order = 1
      parent = child2
      title = top
      command = top
    [[[terminal7]]]
      profile = default
      type = Terminal
      order = 1
      parent = child5
      title = runonce
      command = tail -f /var/log/syslog
    [[[terminal6]]]
      profile = default
      type = Terminal
      order = 0
      parent = child5
      title = syslog
      command = tail -f /var/log/syslog
  [[default]]
    [[[child1]]]
      type = Terminal
      parent = window0
    [[[window0]]]
      type = Window
      parent = ""
[plugins]
END-OF-CONFIG
	chmod 700 /etc/skel/.config/terminator/config
}
function setup_distribute_Config(){
	desc setting up default config \for existing users
	get_user_details all | while read user uid gid home; do
		su -m ${user} < <(cat << END-OF-CMDS
			mkdir -p  "${home}/.config/terminator"
			chmod 700 "${home}/.config/"
			chmod 700 "${home}/.config/terminator"
			cp "/etc/skel/.config/terminator/config" "${home}/.config/terminator/."
END-OF-CMDS
)
	done
}
function setup_runonce_layout(){
	desc layout
	opts='-o ppid --no-heading'
	echo "  PID" = `ps -o pid,ppid,cmd --no-heading -p $$`
	echo " PPID" = `ps -o pid,ppid,cmd --no-heading -p $(ps $opts -p $$)`
	echo "PPPID" = `ps -o pid,ppid,cmd --no-heading -p $(ps $opts -p $(ps $opts -p $$))`

	# get calling funtion log path
	local ppid=$(ps -o ppid --no-heading -p $$)
	local  cmd=`ps -o  cmd --no-heading -p ${ppid} | sed "s|/bin/bash||;s|${buildScriptFQFN}||;s|.sh.*||"`
	#cmd=${cmd//\/bin\/bash/}
	#cmd=${cmd//${buildScriptFQFN}/}
	#cmd=( ${cmd} )
	basename $cmd .sh
	basename `ps -o cmd -p $(ps -o ppid --no-heading -p $$) | awk '{print $3}'` .sh	

}









