#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

while read import; do . "${import}"; done < <(ls -1 "${scriptPath}"/functions.*.sh)

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
    login_shell = True
[layouts]
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
