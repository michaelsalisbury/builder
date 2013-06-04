#!/bin/builder.sh
skip=( false false false false )
step=3
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/defaults/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName

function includes(){
	functions.*.sh
	../functions/functions.*.sh
}

# GLOBAL VARIABLES
#function global_variables(){
#	echo
#}

function setup_skel_Structure(){
	desc Build skel directory structure
	mkdir -p  /etc/skel/.config/terminator
	chmod 700 /etc/skel/.config
	chmod 700 /etc/skel/.config/terminator
}
function setup_make_Config(){
	desc Setting up default config
	# Get parent script log path
	local ppid=$(ps -o ppid --no-heading -p $$)
	local pFQFN=$(ps -o  cmd --no-heading -p $ppid | sed "s|/bin/bash||;s|${buildScriptFQFN}||;s|.sh.*||")
	local pcmd=$(basename ${pFQFN})
	local ppath=$(dirname ${pFQFN})
	local plog="/var/log/$(basename ${buildScriptName} .sh)_${pcmd}/${pcmd}"
	# write config
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
      command = /usr/bin/sudo /bin/bash -c 'cd ${ppath}; /bin/bash -l'
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
      command = tail -f ${plog}
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
	chmod +r /etc/skel/.config
	chmod +r /etc/skel/.config/terminator
	chmod +r /etc/skel/.config/terminator/config
	get_user_details all | while read user uid gid home; do
		cat <<-END-OF-CMDS | su - ${user} -s /bin/bash
			mkdir -p  "${home}/.config/terminator"
			chmod 700 "${home}/.config/"
			chmod 700 "${home}/.config/terminator"
			cp "/etc/skel/.config/terminator/config" "${home}/.config/terminator/."
		END-OF-CMDS
	done
	chmod 700 /etc/skel/.config
	chmod 700 /etc/skel/.config/terminator
	chmod 600 /etc/skel/.config/terminator/config
}

