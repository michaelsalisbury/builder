#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

while read import; do
	. "${import}"
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

read -d $'' g_domains << END-OF-DOMAINS
	cos.ucf.edu
	net.ucf.edu
	mydomain.org
END-OF-DOMAINS

function setup_skel_Structure(){
	desc Build skel directory structure
	touch      /etc/sudoers.d/cifs
	chmod 440  /etc/sudoers.d/cifs
	touch      /etc/xdg/autostart/mount.domain_cifs.desktop
        ln         /etc/xdg/autostart/mount.domain_cifs.desktop /etc/xdg/xdg-xubuntu/autostart/.
        ln         /etc/xdg/autostart/mount.domain_cifs.desktop /etc/xdg/xdg-kubuntu/autostart/.
	mkdir -p   /etc/skel/.scripts
	chmod 700  /etc/skel/.scripts
	mkdir -p   /etc/skel/.logs
	chmod 700  /etc/skel/.logs
	local scriptBase=$(basename "${scriptName}" .sh)
	cp "${scriptPath}/${scriptBase}.mount" /etc/skel/.scripts/mount.domain_cifs.sh
	chmod u+x                              /etc/skel/.scripts/mount.domain_cifs.sh
	for domain in $g_domains; do
		touch     /etc/skel/.cifs-${domain}-cred
		chmod 600 /etc/skel/.cifs-${domain}-cred
		touch     /etc/skel/.cifs-${domain}-shares
		chmod 600 /etc/skel/.cifs-${domain}-shares
	done
	mkdir -p   /etc/skel/.config/xfce4/autostart
	chmod 700  /etc/skel/.config/xfce4
	mkdir -p   /etc/skel/.kde/Autostart
	chmod 700  /etc/skel/.kde
	groupadd -g $(free_group_ID 100) cifs
}
function setup_make_Config(){
	desc Setting up default config
	cat << END-OF-ALIASES > /etc/profile.d/cifs.sh
alias    mount.d='\${HOME}/.scripts/mount.domain_cifs.sh'
alias  mount.dom='\${HOME}/.scripts/mount.domain_cifs.sh'
alias domain.mnt='\${HOME}/.scripts/mount.domain_cifs.sh'
END-OF-ALIASES
	for domain in $g_domains; do
		cat << END-OF-CONF > /etc/skel/.cifs-${domain}-cred
username=[NID]
password=[***]
domain=${domain}
END-OF-CONF
	done
	cat << END-OF-SUDOERS > /etc/sudoers.d/cifs
# cifs
%cifs ALL=(root) NOPASSWD:/sbin/mount.cifs
%cifs ALL=(root) NOPASSWD:/bin/umount -t cifs -v /home/*
END-OF-SUDOERS
	cat << END-OF-DESKTOP > /etc/xdg/autostart/mount.domain_cifs.desktop
[Desktop Entry]
Type=Application
Exec=/bin/bash -c \\\${HOME}/.scripts/mount.domain_cifs.sh
Hidden=false
NoDisplay=true
Terminal=true
X-GNOME-Autostart-enabled=true
Name[en_US]=CIFS Automount
Name=CIFS Automount
Comment[en_US]=
Comment=
END-OF-DESKTOP
	# Modify /etc/adduser.conf to include new group openconnect
	add_default_group cifs
}
function setup_distribute_Config(){
	desc setting up default config \for existing users
	local scriptBase=$(basename "${scriptName}" .sh)
	get_user_details all | while read user uid gid home; do
		usermod -a -G cifs ${user}
		su -m ${user} < <(cat << END-OF-CMDS
			mkdir -p  "${home}/.scripts
			chmod 750 "${home}/.scripts
			mkdir -p  "${home}/.logs
			chmod 750 "${home}/.logs
			cp "/etc/skel/.scrips/mount.domain_cifs.sh" "${home}/.scripts/.
			chmod 750                                   "${home}/.scripts/mount.domain_cifs.sh"
			cp "/etc/skel/.cifs-*"                      "${home}/."
			chmod 600                                   "${home}/.cifs-*
END-OF-CMDS
)
	done
}

