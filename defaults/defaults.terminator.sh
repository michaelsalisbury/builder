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
    copy_on_selection = True
    use_system_font = False
    font = Monospace 13
    scrollbar_position = hidden
    scrollback_infinite = True
[layouts]
  [[default]]
    [[[child0]]]
      position = 74:29
      type = Window
      order = 0
      parent = ""
      size = 1846, 1051
    [[[child1]]]
      position = 923
      type = HPaned
      order = 0
      parent = child0
    [[[child3]]]
      position = 525
      type = VPaned
      order = 1
      parent = child1
    [[[terminal2]]]
      profile = hp-dv6tqe
      type = Terminal
      order = 0
      parent = child1
    [[[terminal5]]]
      profile = hp-dv6tqe
      type = Terminal
      order = 1
      parent = child3
      command = tail -f /var/log/messages /var/log/httpd/access_log
    [[[terminal4]]]
      profile = hp-dv6tqe
      type = Terminal
      order = 0
      parent = child3
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
